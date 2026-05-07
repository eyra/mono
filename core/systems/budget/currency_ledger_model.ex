defmodule Systems.Budget.CurrencyLedgerModel do
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Bookkeeping

  @currencies [:EUR, :USD]

  schema "currency_ledger" do
    field(:currency, Ecto.Enum, values: @currencies)

    belongs_to(:inbound, Bookkeeping.AccountModel)
    belongs_to(:outbound, Bookkeeping.AccountModel)

    timestamps()
  end

  def currencies, do: @currencies

  def create(currency) when currency in @currencies do
    id = currency |> Atom.to_string() |> String.downcase()

    %__MODULE__{
      currency: currency,
      inbound: Bookkeeping.AccountModel.create(["ledger", id, "inbound"]),
      outbound: Bookkeeping.AccountModel.create(["ledger", id, "outbound"])
    }
  end

  def changeset(%__MODULE__{} = ledger, attrs) do
    ledger
    |> cast(attrs, [:currency])
    |> validate_required([:currency])
    |> unique_constraint(:currency)
  end

  def amount_inbound(%{inbound: inbound}) do
    Bookkeeping.AccountModel.balance(inbound)
  end

  def amount_outbound(%{outbound: outbound}) do
    Bookkeeping.AccountModel.balance(outbound)
  end

  def get_by_currency(currency) when currency in @currencies do
    Core.Repo.get_by(__MODULE__, currency: currency)
  end

  def preload_graph(:full), do: [:inbound, :outbound]
end
