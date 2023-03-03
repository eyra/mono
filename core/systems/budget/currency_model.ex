defmodule Systems.Budget.CurrencyModel do
  use Frameworks.Utility.Schema
  require Systems.Budget.CurrencyTypes

  alias Ecto.Changeset
  alias CoreWeb.Cldr

  alias Systems.{
    Budget,
    Content
  }

  schema "currencies" do
    field(:name, :string)
    field(:type, Ecto.Enum, values: Budget.CurrencyTypes.schema_values())
    field(:decimal_scale, :integer)
    belongs_to(:label_bundle, Content.TextBundleModel, on_replace: :update)
    has_one(:bank_account, Budget.BankAccountModel, foreign_key: :currency_id)
    has_many(:budgets, Budget.Model, foreign_key: :currency_id)

    timestamps()
  end

  @fields ~w(name type decimal_scale)a
  @required_fields @fields

  def create(name, type, decimal_scale, %Content.TextBundleModel{} = label_bundle) do
    %__MODULE__{
      name: name,
      type: type,
      decimal_scale: decimal_scale,
      label_bundle: label_bundle
    }
  end

  def create(name, type, decimal_scale, label) do
    label_bundle = Content.TextBundleModel.translate(label)
    create(name, type, decimal_scale, label_bundle)
  end

  def prepare(%{label_bundle: %{id: _id}} = currency) do
    currency
    |> Changeset.change()
  end

  def prepare(currency) do
    label_bundle = %Content.TextBundleModel{
      items: [%Content.TextItemModel{locale: "*", text: "? %{amount}"}]
    }

    currency
    |> Changeset.change()
    |> Changeset.put_assoc(:label_bundle, label_bundle)
  end

  def change(currency, attrs) do
    currency
    |> cast(attrs, @fields)
    |> cast_assoc(:label_bundle, with: &Content.TextBundleModel.change/2)
  end

  def validate(%Changeset{} = changeset) do
    changeset
    |> Changeset.validate_required(@required_fields)
    |> Changeset.unique_constraint(:name)
  end

  def preload_graph(:full), do: preload_graph([:label_bundle, :bank_account])

  def preload_graph(:label_bundle),
    do: [label_bundle: Content.TextBundleModel.preload_graph(:full)]

  def preload_graph(:bank_account),
    do: [bank_account: [:account]]

  def title(%{name: name, label_bundle: label_bundle}, locale) do
    Content.TextBundleModel.text(label_bundle, locale, name, name)
  end

  def label(%{decimal_scale: nil} = currency, locale, amount) when is_integer(amount) do
    label(currency, locale, Integer.to_string(amount))
  end

  def label(%{decimal_scale: 2} = currency, locale, amount) when is_integer(amount) do
    {:ok, amount_string} = Cldr.Number.to_string(amount / 100, locale: locale, format: :currency)
    amount_string = Regex.replace(~r"[^\d.,]", amount_string, "")
    label(currency, locale, amount_string)
  end

  def label(%{decimal_scale: decimal_scale} = currency, locale, amount) when is_integer(amount) do
    amount_string =
      (amount / :math.pow(10, decimal_scale))
      |> Decimal.from_float()
      |> Decimal.round(decimal_scale)
      |> Decimal.to_string()

    label(currency, locale, amount_string)
  end

  def label(%{name: name, label_bundle: label_bundle}, locale, amount) when is_binary(amount) do
    default = "#{amount} (#{name})"
    Content.TextBundleModel.text(label_bundle, locale, amount, default)
  end

  def label(%{name: name, label_bundle: label_bundle}, locale, nil) do
    Content.TextBundleModel.text(label_bundle, locale, nil, name)
  end
end
