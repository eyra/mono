defmodule Systems.Budget.CurrencyModel do
  use Frameworks.Utility.Schema

  alias Systems.{
    Content
  }

  schema "currencies" do
    field(:name, :string, null: false)
    field(:decimal_scale, :integer)
    belongs_to(:label_bundle, Content.TextBundleModel)

    timestamps()
  end

  def preload_graph(:full), do: preload_graph([:label_bundle])

  def preload_graph(:label_bundle),
    do: [label_bundle: Content.TextBundleModel.preload_graph(:full)]

  def label(%{decimal_scale: nil} = currency, locale, amount) when is_integer(amount) do
    label(currency, locale, Integer.to_string(amount))
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
