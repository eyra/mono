defmodule Systems.Budget.BankAccountModel do
  use Frameworks.Utility.Schema
  require Systems.Budget.CurrencyTypes

  alias Ecto.Changeset
  import Frameworks.Utility.EctoHelper

  alias Systems.{
    Budget,
    Bookkeeping
  }

  @icon_type :emoji
  @account_type :bank

  schema "bank_accounts" do
    field(:name, :string)
    field(:icon, Frameworks.Utility.EctoTuple)
    field(:virtual_icon, :string, virtual: true)

    belongs_to(:currency, Budget.CurrencyModel,
      on_replace: :update,
      defaults: [type: :legal, decimal_scale: 2]
    )

    belongs_to(:account, Bookkeeping.AccountModel, on_replace: :update)

    timestamps()
  end

  @fields ~w(name virtual_icon)a
  @required_fields @fields

  def create(name, icon, type, decimal_scale, label) do
    %__MODULE__{
      name: name,
      icon: {:emoji, icon},
      currency: Budget.CurrencyModel.create(name, type, decimal_scale, label),
      account: Bookkeeping.AccountModel.create(to_identifier(name))
    }
  end

  def prepare(%{currency: %{id: _id}} = bank_account) do
    bank_account
    |> prepare_virtual_icon()
    |> Changeset.change()
  end

  def prepare(bank_account) do
    currency_changeset =
      %Budget.CurrencyModel{}
      |> Budget.CurrencyModel.prepare()

    bank_account
    |> prepare_virtual_icon()
    |> Changeset.change()
    |> Changeset.put_assoc(:currency, currency_changeset)
  end

  def change(bank_account, attrs) do
    bank_account
    |> prepare_virtual_icon()
    |> Changeset.cast(attrs, @fields)
    |> Changeset.cast_assoc(:currency, with: &Budget.CurrencyModel.change/2)
    |> apply_virtual_icon_change(@icon_type)
  end

  def validate(changeset, condition \\ true) do
    if condition do
      changeset
      |> Changeset.validate_required(@required_fields)
      |> validate_currency()
    else
      changeset
    end
  end

  defp validate_currency(%{changes: %{currency: currency_changeset}} = changeset) do
    changeset
    |> Changeset.put_assoc(:currency, Budget.CurrencyModel.validate(currency_changeset))
  end

  defp validate_currency(changeset), do: changeset

  def submit(%Changeset{data: %{account: %{id: _id}}} = changeset) do
    changeset
  end

  def submit(%Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()

    changeset
    |> Changeset.put_assoc(:account, Bookkeeping.AccountModel.create({:bank, uuid}))
  end

  def to_identifier(name) do
    Bookkeeping.AccountModel.to_identifier({@account_type, name})
  end

  def preload_graph(:full) do
    [:account, currency: Budget.CurrencyModel.preload_graph(:full)]
  end
end
