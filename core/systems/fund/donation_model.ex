defmodule Systems.Fund.DonationModel do
  @moduledoc """
  Aggregates the `Fund.RewardModel` rows a participant donated to Eyra in a
  single provider charge, waiving the right to have them paid out.

  Unlike a payout, a donation is a **one-leg saga**: the money is already on the
  platform merchant, so there is nothing to transfer to the participant and
  nothing to withdraw. One charge moves it from Eyra-as-merchant to
  Eyra-as-partner, and `status` says everything there is to know about it. That
  is why there is no `phase/1` here — do not port `Fund.PayoutModel.phase/1`
  over, there is no second leg for it to distinguish.

  A donation stuck at `:pending` means we do not know whether the provider took
  the charge. It is resolved by hand (charges cannot be listed at OPP and there
  is no charge webhook), and deliberately so: the worst case is that money which
  should sit in Eyra's partner balance still sits in Eyra's merchant balance. No
  participant can be underpaid or double-paid by it.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Fund

  @statuses [:pending, :completed, :failed]

  schema "fund_donations" do
    field(:uid, Ecto.UUID, autogenerate: true)

    field(:amount_cents, :integer)
    field(:currency, :string, default: "eur")
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:charge_uid, :string)
    field(:failure_reason, :string)

    belongs_to(:user, Account.User)
    has_many(:rewards, Fund.RewardModel, foreign_key: :donation_id)

    timestamps()
  end

  def statuses, do: @statuses

  @doc """
  Idempotency key for the charge.

  It carries no attempt counter, by design: replaying the same key is safe (the
  provider de-duplicates it), while minting a fresh one would take the money a
  second time. Also written as the charge's `metadata.reference`, which is what
  a stuck donation is found by in the provider dashboard.
  """
  def charge_key(%__MODULE__{uid: uid}) when is_binary(uid),
    do: "donation=#{uid},type=charge"

  @required_fields ~w(user_id amount_cents)a
  @optional_fields ~w(currency status charge_uid failure_reason)a
  @fields @required_fields ++ @optional_fields

  def changeset(donation, attrs) do
    donation
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
  end

  def preload_graph(:full), do: [:user, :rewards]
end
