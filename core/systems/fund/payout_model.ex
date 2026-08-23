defmodule Systems.Fund.PayoutModel do
  @moduledoc """
  Aggregates the `Fund.RewardModel` rows paid out in a single provider withdrawal.

  A payout runs a two-leg saga: transfer the money from the platform merchant to
  the participant's merchant, then withdraw it from there to their bank.

  `status` mirrors what the provider says about the *withdrawal* — `:pending`,
  `:completed` or `:failed`. It cannot say how far the saga got, which is a
  different question and the one that decides what is safe to do next. That is
  what `phase/1` answers, derived from `funds_committed_at` and `provider_uid`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Fund

  @statuses [:pending, :completed, :failed]

  @type phase ::
          :awaiting_transfer
          | :awaiting_withdrawal
          | :awaiting_provider
          | :withdrawal_retryable
          | :completed
          | :failed

  schema "fund_payouts" do
    # Restore-stable identity: the provider idempotency keys derive from this and
    # not from the serial id, which a PITR restore rewinds.
    field(:uid, Ecto.UUID, autogenerate: true)

    field(:amount_cents, :integer)
    field(:currency, :string, default: "eur")
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:provider_uid, :string)
    field(:transfer_uid, :string)
    field(:funds_committed_at, :naive_datetime)
    field(:withdrawal_attempt, :integer, default: 0)
    field(:failure_reason, :string)

    belongs_to(:user, Account.User)
    has_many(:rewards, Fund.RewardModel, foreign_key: :payout_id)

    timestamps()
  end

  def statuses, do: @statuses

  @doc """
  How far the payout saga actually got — the question `status` cannot answer.

  * `:awaiting_transfer` — the transfer is unconfirmed. It may never have been
    sent, or the provider may have taken it and we lost the response.
  * `:awaiting_withdrawal` — the money is on the participant's merchant, but no
    withdrawal uid was recorded. Either none was created, or one was and we lost
    the response. Stranded: the participant sees no payout and no button.
  * `:awaiting_provider` — the withdrawal is issued; waiting on a terminal status.
    The normal in-flight state.
  * `:withdrawal_retryable` — the provider rejected the withdrawal *after* the
    transfer landed. The money sits on the participant's merchant and the rewards
    stay locked. Recoverable by issuing a fresh withdrawal, never by releasing
    the lock (that would charge the platform twice).
  * `:failed` — the transfer was definitively rejected; nothing moved and the
    lock was released. Terminal and safe.
  * `:completed` — the money reached the participant's bank.
  """
  @spec phase(t :: %__MODULE__{}) :: phase()
  def phase(%__MODULE__{status: :completed}), do: :completed
  def phase(%__MODULE__{status: :failed, funds_committed_at: nil}), do: :failed
  def phase(%__MODULE__{status: :failed}), do: :withdrawal_retryable
  def phase(%__MODULE__{funds_committed_at: nil}), do: :awaiting_transfer
  def phase(%__MODULE__{provider_uid: nil}), do: :awaiting_withdrawal
  def phase(%__MODULE__{}), do: :awaiting_provider

  @doc """
  Idempotency key for the transfer leg.

  It carries no attempt counter, by design: a transfer is never re-issued under a
  fresh key. Replaying the *same* key is safe (the provider de-duplicates it, at
  least while it still remembers it); minting a new one would move the money a
  second time.
  """
  def transfer_key(%__MODULE__{uid: uid}) when is_binary(uid),
    do: "payout=#{uid},type=transfer"

  @doc """
  Idempotency key for the withdrawal leg.

  A withdrawal the provider created and then rejected keeps its key, so a retry
  must present a fresh one — hence the attempt counter. The `payout=<uid>` prefix
  is what a stranded withdrawal is later found by, via its `reference`.
  """
  def withdrawal_key(%__MODULE__{uid: uid, withdrawal_attempt: attempt})
      when is_binary(uid) and is_integer(attempt),
      do: "payout=#{uid},type=withdrawal,attempt=#{attempt}"

  @doc """
  Prefix shared by every withdrawal attempt of this payout — used to match a
  withdrawal back to its payout when only the provider's `reference` is known.
  """
  def withdrawal_key_prefix(%__MODULE__{uid: uid}) when is_binary(uid),
    do: "payout=#{uid},type=withdrawal"

  @required_fields ~w(user_id amount_cents)a
  @optional_fields ~w(currency status provider_uid transfer_uid funds_committed_at withdrawal_attempt failure_reason)a
  @fields @required_fields ++ @optional_fields

  def changeset(payout, attrs) do
    payout
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
  end

  def preload_graph(:full), do: [:user, :rewards]
end
