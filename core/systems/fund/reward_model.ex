defmodule Systems.Fund.RewardModel do
  @moduledoc """
  The fund reward type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account

  alias Systems.{
    Fund,
    Bookkeeping
  }

  @statuses [:reserved, :pending_approval, :approved, :rejected, :paid]

  schema "fund_rewards" do
    field(:idempotence_key, :string)
    field(:amount, :integer)
    field(:attempt, :integer)
    field(:status, Ecto.Enum, values: @statuses, default: :reserved)
    belongs_to(:fund, Fund.Model)
    belongs_to(:user, Account.User)

    belongs_to(:deposit, Bookkeeping.EntryModel)
    belongs_to(:payment, Bookkeeping.EntryModel)

    timestamps()
  end

  def statuses, do: @statuses

  @required_fields ~w(idempotence_key amount)a
  @optional_fields ~w(attempt status)a
  @fields @required_fields ++ @optional_fields

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:idempotence_key)
  end

  def preload_graph(:full) do
    [
      :user,
      payment: [lines: [:account]],
      deposit: [lines: [:account]],
      fund: Fund.Model.preload_graph(:full)
    ]
  end

  def deposit_idempotence_key(%Fund.RewardModel{
        idempotence_key: idempotence_key,
        attempt: attempt
      }),
      do: "#{idempotence_key},type=deposit,attempt=#{attempt}"

  def payment_idempotence_key(%Fund.RewardModel{idempotence_key: idempotence_key}),
    do: payment_idempotence_key(idempotence_key)

  def payment_idempotence_key(reward_idempotence_key),
    do: "#{reward_idempotence_key},type=payment"
end
