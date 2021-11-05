defmodule Systems.Campaign.Model do
  @moduledoc """
  The campaign type.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  schema "campaigns" do
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:promotion, Promotion.Model)
    belongs_to(:promotable_assignment, Assignment.Model)

    has_many(:role_assignments, through: [:auth_node, :role_assignments])
    has_many(:authors, Campaign.AuthorModel, foreign_key: :campaign_id)

    timestamps()
  end

  @required_fields ~w()a
  @optional_fields ~w(updated_at)a
  @fields @required_fields ++ @optional_fields

  defimpl GreenLight.AuthorizationNode do
    def id(campaign), do: campaign.auth_node_id
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def flatten(campaign) do
    campaign
    |> Map.take([:id, :promotion, :authors])
    |> Map.put(:promotable, promotable(campaign))
  end

  def promotable(%{promotable_assignment: promotable}) when not is_nil(promotable), do: promotable
  def promotable(%{id: id}), do: raise "no promotable object available for campaign #{id}"

  def preload_graph(:full) do
    [
      authors: [:user],
      promotion: [:content_node, submission: [:criteria]],
      promotable_assignment: Assignment.Model.preload_graph(:full)
    ]
  end
  def preload_graph(_), do: []

end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Campaign.Model do

  import Frameworks.Utility.ViewModel
  import CoreWeb.Gettext

  alias Frameworks.Utility.ViewModelBuilder, as: Builder

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  def view_model(%Campaign.Model{} = campaign, page, user, url_resolver) do
    campaign
    |> Campaign.Model.flatten()
    |> vm(page, user, url_resolver)
  end

  defp vm(%{id: id, promotion: %{expectations: expectations} = promotion, promotable: promotable}, Assignment.LandingPage = page, user, url_resolver) do
    %{id: id}
    |> merge(Builder.view_model(promotion, page, user, url_resolver))
    |> merge(Builder.view_model(promotable, page, user, url_resolver))
    |> required(:subtitle, dgettext("eyra-assignment", "subtitle.label"))
    |> required(:text, expectations)
  end

  defp vm(%{id: id, promotion: promotion, promotable: promotable}, Assignment.CallbackPage = page, user, url_resolver) do
    %{id: id}
    |> merge(Builder.view_model(promotion, page, user, url_resolver))
    |> merge(Builder.view_model(promotable, page, user, url_resolver))
  end

  defp vm(%{id: id, authors: authors, promotion: promotion, promotable: promotable}, Promotion.LandingPage = page, user, url_resolver) do
    %{id: id}
    |> merge(vm(authors, page))
    |> merge(Builder.view_model(promotion, page, user, url_resolver))
    |> merge(Builder.view_model(promotable, page, user, url_resolver))
    |> required(:subtitle, dgettext("eyra-promotion", "subtitle.label"))
  end

  defp vm(authors, Promotion.LandingPage) when is_list(authors) do
    %{
      byline:
        "#{dgettext("link-survey", "by.author.label")}: "
        <> (authors
          |> Enum.map(& &1.fullname)
          |> Enum.join(", "))
    }
  end
end
