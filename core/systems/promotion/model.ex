defmodule Systems.Promotion.Model do
  @moduledoc """
  The promotion schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model

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
    field(:themes, {:array, :string})
    # Technical
    field(:director, Ecto.Enum, values: [:campaign])

    has_one(:submission, Core.Pools.Submission, foreign_key: :promotion_id)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @plain_fields ~w(title subtitle expectations description banner_photo_url banner_title banner_subtitle banner_url)a
  @rich_fields ~w(themes image_id marks)a
  @technical_fields ~w(director)a

  @fields @plain_fields ++ @rich_fields ++ @technical_fields

  @publish_required_fields ~w(title subtitle expectations description banner_title banner_subtitle)a

  def plain_fields, do: @plain_fields

  @impl true
  def operational_fields, do: @publish_required_fields

  @impl true
  def operational_validation(changeset), do: changeset

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(promotion), do: promotion.auth_node_id
  end

  def preload_graph(:full) do
    [:submission]
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
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
    |> validate_required([:title])
  end
end
