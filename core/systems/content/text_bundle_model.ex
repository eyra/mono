defmodule Systems.Content.TextBundleModel do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Systems.{
    Content
  }

  schema "text_bundles" do
    has_many(:items, Content.TextItemModel,
      foreign_key: :bundle_id,
      on_replace: :delete_if_exists
    )

    timestamps()
  end

  @fields ~w()a

  def translate(items) when is_list(items) do
    %__MODULE__{
      items: Enum.map(items, &Content.TextItemModel.translate(&1))
    }
  end

  def apply_text_bundle_changes(changeset, attrs, field) do
    text_bundle_changeset =
      Content.TextBundleModel.change(
        Map.get(changeset.data, field),
        Map.get(attrs, Atom.to_string(field), %{})
      )

    put_assoc(changeset, field, text_bundle_changeset)
  end

  def preload_graph(:full) do
    order_by_query = from(text_item in Content.TextItemModel, order_by: [asc: text_item.locale])
    [items: order_by_query]
  end

  def change(bundle, attrs) do
    bundle
    |> cast(attrs, @fields)
    |> cast_assoc(:items, with: &Content.TextItemModel.change/2)
  end

  def text(bundle, locale, amount \\ nil, default \\ "<text?>")

  def text(bundle, locale, amount, default) do
    case item(bundle, locale) do
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
