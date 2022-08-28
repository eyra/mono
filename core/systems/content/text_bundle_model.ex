defmodule Systems.Content.TextBundleModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Content
  }

  schema "text_bundles" do
    has_many(:items, Content.TextItemModel, foreign_key: :bundle_id)
    timestamps()
  end

  @fields ~w()a

  def preload_graph(:full), do: [:items]

  def changeset(bundle, attrs) do
    bundle
    |> cast(attrs, @fields)
  end

  def text(bundle, locale, amount \\ nil, default \\ "<text?>")

  def text(bundle, locale, amount, default) do
    case Content.TextBundleModel.item(bundle, locale) do
      %Content.TextItemModel{} = item -> Content.TextItemModel.text(item, amount)
      _ -> default
    end
  end

  def item(%{items: items}, locale) when not is_nil(items) do
    case Enum.find(items, &(&1.locale == locale)) do
      %Content.TextItemModel{} = item -> item
      _ -> List.first(items)
    end
  end

  def item(_, _locale), do: nil
end
