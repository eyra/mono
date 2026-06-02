defmodule Systems.Fund.PayoutModel do
  @moduledoc """
  A payout aggregates one or more `Fund.RewardModel` rows that are paid out
  to a participant in a single OPP withdrawal.

  Lifecycle mirrors the pay-in side (`Budget.TransactionModel`):

      :pending    — created locally; OPP request in-flight.
      :completed  — terminal success; OPP released funds to the participant.
      :failed     — terminal failure (OPP "failed" or "disapproved", or any
                    rollback prior to OPP accepting the call).

  OPP's intermediate statuses (`new`, `pending`, `approved`) are not
  persisted locally — they collapse into our `:pending`. `:disapproved`
  collapses into `:failed`; the OPP string is captured in
  `failure_reason` for audit.

  `provider_uid` is the OPP withdrawal UID; populated as soon as
  `Payment.Public.create_withdrawal/3` returns successfully.
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
