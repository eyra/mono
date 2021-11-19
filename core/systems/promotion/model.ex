defmodule Systems.Promotion.Model do
  @moduledoc """
  The promotion schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.{
    Promotion
  }

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
    belongs_to(:content_node, Core.Content.Node)
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

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Promotion.Model do

  import Map, only: [take: 2]
  import Frameworks.Utility.ViewModel
  import CoreWeb.Gettext

  alias Core.Marks

  alias Systems.{
    Promotion,
    Assignment
  }

  def view_model(%Promotion.Model{} = promotion, page, _user, _url_resolver) do
    promotion
    |> vm(page)
  end

  defp vm(%{title: title, submission: submission}, Assignment.LandingPage) do
    %{title: title, highlights: highlights(submission)}
  end

  defp vm(%{title: title}, Assignment.CallbackPage) do
    %{title: title}
  end

  defp vm(%{submission: submission, themes: themes, marks: marks} = promotion, Promotion.LandingPage) do
    promotion
    |> take([:image_id | Promotion.Model.plain_fields])
    |> merge(
      %{
        themes: themes(themes, Link.Enums.Themes),
        organisation: organisation(marks),
        highlights: highlights(submission)
      }
    )
  end

  defp themes(themes, themes_module) do
    themes
    |> themes_module.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.value)
    |> Enum.join(", ")
  end

  defp organisation(marks) do
    if id = organisation_id(marks) do
      Enum.find(
        Marks.instances(),
        &(&1.id == id)
      )
    end
  end

  defp organisation_id([first_mark | _]), do: first_mark
  defp organisation_id(_), do: nil

  defp highlights(%{reward_value: reward_value}) do
    reward_title = dgettext("link-survey", "reward.highlight.title")

    reward_value =
      case reward_value do
        nil -> "?"
        value -> value
      end

    reward_text = "#{reward_value} credits"

    [%{title: reward_title, text: reward_text}]
  end

end
