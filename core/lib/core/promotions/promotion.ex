defmodule Core.Promotions.Promotion do
  @moduledoc """
  The promotion schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  require Core.Themes
  alias Core.Themes
  alias Core.Marks

  import Ecto.Changeset

  schema "promotions" do
    # Plain Content
    field(:title, :string)
    field(:subtitle, :string)
    field(:expectations, :string)
    field(:description, :string)
    field(:banner_photo_url, :string)
    field(:banner_title, :string)
    field(:banner_subtitle, :string)
    field(:banner_url, :string)
    # Rich Content
    field(:image_id, :string)
    field(:marks, {:array, :string})
    field(:themes, {:array, Ecto.Enum}, values: Themes.theme_values())
    field(:published_at, :naive_datetime)
    # Technical
    field(:plugin, :string)

    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @plain_fields ~w(title subtitle expectations description banner_photo_url banner_title banner_subtitle banner_url)a
  @rich_fields ~w(themes image_id marks published_at)a
  @technical_fields ~w(plugin)a

  @fields @plain_fields ++ @rich_fields ++ @technical_fields

  @impl true
  def operational_fields, do: @plain_fields ++ @rich_fields

  defimpl GreenLight.AuthorizationNode do
    def id(promotion), do: promotion.auth_node_id
  end

  def to_map(promotion) do
    promotion
    |> Map.take(@fields)
  end

  defp put_default(map, key, value) do
    Map.update(map, key, value, &(&1 || value))
  end

  @doc false
  def changeset(promotion, attrs) do
    promotion
    |> cast(attrs, @fields)
    |> validate_required([:title, :plugin])
  end

  def published?(%__MODULE__{published_at: published_at}) do
    !is_nil(published_at)
  end

  def get_themes(promotion) do
    promotion.themes
    |> Themes.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.value)
    |> Enum.join(", ")
  end

  def get_organisation(promotion) do
    case get_organisation_id(promotion) do
      nil ->
        nil

      id ->
        Marks.instances()
        |> Enum.find(&(&1.id === String.to_existing_atom(id)))
    end
  end

  defp get_organisation_id(%__MODULE__{marks: [first_mark | _]}), do: first_mark
  defp get_organisation_id(_), do: nil
end
