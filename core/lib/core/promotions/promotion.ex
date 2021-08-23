defmodule Core.Promotions.Promotion do
  @moduledoc """
  The promotion schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  import Ecto.Changeset
  import CoreWeb.Gettext

  require Core.Enums.Themes
  alias Core.Enums.Themes
  alias Core.Marks
  alias Core.ImageHelpers
  alias EyraUI.Timestamp

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
    field(:themes, {:array, Ecto.Enum}, values: Themes.schema_values())
    # Technical
    field(:plugin, :string)

    has_one(:submission, Core.Pools.Submission)
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @plain_fields ~w(title subtitle expectations description banner_photo_url banner_title banner_subtitle banner_url)a
  @rich_fields ~w(themes image_id marks)a
  @technical_fields ~w(plugin)a

  @fields @plain_fields ++ @rich_fields ++ @technical_fields

  @publish_required_fields ~w(title subtitle expectations description banner_title banner_subtitle)a

  @impl true
  def operational_fields, do: @publish_required_fields

  defimpl GreenLight.AuthorizationNode do
    def id(promotion), do: promotion.auth_node_id
  end

  def to_map(promotion) do
    promotion
    |> Map.take(@fields)
  end

  def changeset(promotion, :publish, params) do
    promotion
    |> cast(params, @fields)
    |> validate_required(@publish_required_fields)
  end

  def changeset(promotion, _, attrs) do
    promotion
    |> cast(attrs, @fields)
    |> validate_required([:title, :plugin])
  end

  def get_themes(promotion) do
    promotion.themes
    |> Themes.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.value)
    |> Enum.join(", ")
  end

  def get_organisation(promotion) do
    if id = get_organisation_id(promotion) do
      Enum.find(
        Marks.instances(),
        &(&1.id == id)
      )
    end
  end

  defp get_organisation_id(%__MODULE__{marks: [first_mark | _]}), do: first_mark
  defp get_organisation_id(_), do: nil

  def get_byline(promotion) do
    label = dgettext("eyra-promotion", "created.label")
    timestamp = Timestamp.humanize(promotion.inserted_at)
    "#{label}: #{timestamp}"
  end

  def get_image_url(%{image_id: image_id}, %{width: width, height: height}) do
    image_id
    |> ImageHelpers.get_image_info(width, height)
    |> Map.get(:url)
  end
end
