defmodule Systems.Budget.RewardModel do
  @moduledoc """
  The budget type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Accounts

  alias Systems.{
    Budget,
    Bookkeeping
  }

  schema "budget_rewards" do
    field(:idempotence_key, :string)
    field(:amount, :integer)
    field(:attempt, :integer)
    belongs_to(:budget, Budget.Model)
    belongs_to(:user, Accounts.User)

    belongs_to(:deposit, Bookkeeping.EntryModel)
    belongs_to(:payment, Bookkeeping.EntryModel)

    timestamps()
  end

  @required_fields ~w(idempotence_key amount)a
  @optional_fields ~w(attempt)a
  @fields @required_fields ++ @optional_fields

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:idempotence_key)
  end

  def preload_graph(:full) do
    [:deposit, :payment, :user, budget: Budget.Model.preload_graph(:full)]
  end

  def deposit_idempotence_key(%Budget.RewardModel{
        idempotence_key: idempotence_key,
        attempt: attempt
      }),
      do: "#{idempotence_key},type=deposit,attempt=#{attempt}"

  def payment_idempotence_key(%Budget.RewardModel{idempotence_key: idempotence_key}),
    do: payment_idempotence_key(idempotence_key)

  def payment_idempotence_key(reward_idempotence_key),
    do: "#{reward_idempotence_key},type=payment"
end
