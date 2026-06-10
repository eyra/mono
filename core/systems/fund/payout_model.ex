defmodule Systems.Fund.PayoutModel do
  @moduledoc """
  Aggregates the `Fund.RewardModel` rows paid out in a single OPP withdrawal.

  Status collapses OPP's vocabulary into `:pending` (in-flight, incl. OPP's
  new/pending/approved), `:completed`, and `:failed` (incl. disapproved or a
  pre-acceptance rollback; the OPP string is kept in `failure_reason`).
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Fund

  @statuses [:pending, :completed, :failed]

  schema "fund_payouts" do
    field(:amount_cents, :integer)
    field(:currency, :string, default: "eur")
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:provider_uid, :string)
    field(:failure_reason, :string)

    belongs_to(:user, Account.User)
    has_many(:rewards, Fund.RewardModel, foreign_key: :payout_id)

    timestamps()
  end

  def statuses, do: @statuses

  @doc """
  Stable idempotency key for the OPP withdrawal, keyed by the payout `id` so
  retries re-issue the same withdrawal instead of duplicating it.
  """
  def idempotence_key(%__MODULE__{id: id}) when is_integer(id), do: "payout=#{id}"

  @required_fields ~w(user_id amount_cents)a
  @optional_fields ~w(currency status provider_uid failure_reason)a
  @fields @required_fields ++ @optional_fields

  def changeset(payout, attrs) do
    payout
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
  end

  def preload_graph(:full), do: [:user, :rewards]
end
