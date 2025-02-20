defmodule Systems.Budget.Model do
  @moduledoc """
  The budget type.
  """
  use Core, :auth
  use Ecto.Schema
  import Frameworks.Utility.EctoHelper

  alias Systems.Account.User
  alias Ecto.Changeset

  alias Systems.{
    Budget,
    Bookkeeping
  }

  @icon_type :emoji

  schema "budgets" do
    field(:name, :string)
    field(:icon, Frameworks.Utility.EctoTuple)
    field(:virtual_icon, :string, virtual: true)
    belongs_to(:currency, Budget.CurrencyModel)
    belongs_to(:fund, Bookkeeping.AccountModel)
    belongs_to(:reserve, Bookkeeping.AccountModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:rewards, Budget.RewardModel, foreign_key: :budget_id)

    timestamps()
  end

  @fields ~w(name virtual_icon)a
  @required_fields @fields

  def create(%Budget.CurrencyModel{} = currency, name, icon) do
    %__MODULE__{
      name: name,
      icon: icon,
      currency: currency,
      fund: Bookkeeping.AccountModel.create({:fund, name}),
      reserve: Bookkeeping.AccountModel.create({:reserve, name}),
      auth_node: auth_module().prepare_node()
    }
  end

  def create(%Budget.CurrencyModel{} = currency, name, icon, %User{} = user) do
    uuid = Ecto.UUID.generate()

    %__MODULE__{
      name: name,
      icon: icon,
      currency: currency,
      fund: Bookkeeping.AccountModel.create({:fund, uuid}),
      reserve: Bookkeeping.AccountModel.create({:reserve, uuid}),
      auth_node: auth_module().prepare_node(user, :owner)
    }
  end

  def create(name, icon, type, decimal_scale, label) do
    %__MODULE__{
      name: name,
      icon: icon,
      fund: Bookkeeping.AccountModel.create({:fund, name}),
      reserve: Bookkeeping.AccountModel.create({:reserve, name}),
      currency: Budget.CurrencyModel.create(name, type, decimal_scale, label),
      auth_node: auth_module().prepare_node()
    }
  end

  def prepare(budget) do
    budget
    |> prepare_virtual_icon()
    |> Changeset.change()
  end

  def change(budget, attrs) do
    budget
    |> prepare_virtual_icon()
    |> Changeset.cast(attrs, @fields)
    |> apply_virtual_icon_change(@icon_type)
  end

  def validate(changeset, condition \\ true) do
    if condition do
      changeset
      |> Changeset.validate_required(@required_fields)
    else
      changeset
    end
  end

  def submit(%Ecto.Changeset{} = changeset), do: changeset

  def submit(
        %Ecto.Changeset{} = changeset,
        %User{} = user,
        %Budget.CurrencyModel{} = currency
      ) do
    uuid = Ecto.UUID.generate()

    changeset
    |> Changeset.put_assoc(:currency, currency)
    |> Changeset.put_assoc(:auth_node, auth_module().prepare_node(user, :owner))
    |> Changeset.put_assoc(:fund, Bookkeeping.AccountModel.create({:fund, uuid}))
    |> Changeset.put_assoc(:reserve, Bookkeeping.AccountModel.create({:reserve, uuid}))
  end

  def preload_graph(:full) do
    [:fund, :reserve, currency: Budget.CurrencyModel.preload_graph(:full)]
  end

  def amount_available(%{fund: fund}) do
    Bookkeeping.AccountModel.balance(fund)
  end

  def amount_reserved(%{reserve: reserve}) do
    Bookkeeping.AccountModel.balance(reserve)
  end

  def amount_spend(%{fund: %{balance_debit: balance_debit}, reserve: reserve}) do
    balance_debit - Bookkeeping.AccountModel.balance(reserve)
  end
end

defimpl Frameworks.GreenLight.AuthorizationNode, for: Systems.Budget.Model do
  def id(budget), do: budget.auth_node_id
end
