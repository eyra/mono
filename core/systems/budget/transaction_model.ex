defmodule Systems.Budget.TransactionModel do
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Fund

  @statuses [:pending, :completed, :failed, :expired]

  schema "transactions" do
    field(:transaction_id, :string)
    field(:status, Ecto.Enum, values: @statuses)
    field(:idempotence_key, :string)

    belongs_to(:user, Account.User)
    belongs_to(:target_fund, Fund.Model)

    timestamps()
  end

  @fields ~w(transaction_id status idempotence_key)a
  @required_fields @fields

  def changeset(%__MODULE__{} = transaction, attrs) do
    transaction
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:idempotence_key)
  end

  def preload_graph(:down), do: [target_fund: Fund.Model.preload_graph(:full)]
  def preload_graph(:up), do: [:user]
end
