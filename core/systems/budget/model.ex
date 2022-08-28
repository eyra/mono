defmodule Systems.Budget.Model do
  @moduledoc """
  The budget type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Budget,
    Bookkeeping
  }

  schema "budgets" do
    field(:name, :string)
    belongs_to(:currency, Budget.CurrencyModel)
    belongs_to(:fund, Bookkeeping.AccountModel)
    belongs_to(:reserve, Bookkeeping.AccountModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:rewards, Budget.RewardModel, foreign_key: :budget_id)

    timestamps()
  end

  @fields ~w(name)a
  @required_fields @fields

  @doc false
  def changeset(budget, attrs) do
    budget
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:full) do
    [:fund, :reserve, currency: Budget.CurrencyModel.preload_graph(:full)]
  end
end

defimpl Frameworks.GreenLight.AuthorizationNode, for: Systems.Budget.Model do
  def id(budget), do: budget.auth_node_id
end
