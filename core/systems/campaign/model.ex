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

  defimpl Frameworks.GreenLight.AuthorizationNode do
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
    |> Map.take([:id, :promotion, :authors, :updated_at])
    |> Map.put(:promotable, promotable(campaign))
  end

  def promotable(%{promotable_assignment: promotable}) when not is_nil(promotable), do: promotable
  def promotable(%{id: id}), do: raise "no promotable object available for campaign #{id}"

  def preload_graph(:full) do
    [
      :auth_node,
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
    Assignment,
    Crew
  }

  alias Core.Content.Nodes
  alias Core.ImageHelpers
  alias Core.Pools.Submission

  def view_model(%Campaign.Model{} = campaign, page, user, url_resolver) do
    campaign
    |> Campaign.Model.flatten()
    |> vm(page, user, url_resolver)
  end

  defp vm(%{id: id, promotion: %{expectations: expectations} = promotion, promotable: promotable}, Assignment.LandingPage = page, user, url_resolver) do
    %{id: id}
    |> merge(Builder.view_model(promotion, page, user, url_resolver))
    |> merge(Builder.view_model(promotable, page, user, url_resolver))
    |> required(:subtitle, dgettext("eyra-promotion", "expectations.public.label"))
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

  defp vm(%{
    id: id,
    updated_at: updated_at,
    promotion: %{
      title: title,
      image_id: image_id,
      submission: %{reward_value: reward_value}
    },
    promotable: %{
      crew: crew
    } = assignment
  }, Link.Marketplace, user, url_resolver) do

    task =
      case Crew.Context.get_member!(crew, user) do
        nil -> nil
        member -> Crew.Context.get_task(crew, member)
      end

    tag = tag(task)
    subtitle = subtitle(task, reward_value)
    quick_summary =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      id: id,
      path: url_resolver.(Assignment.LandingPage, assignment.id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end

  defp vm(%{
    id: id,
    updated_at: updated_at,
    promotion: %{
      title: title,
      image_id: image_id,
      content_node: promotion_content_node,
      submission: submission
    },
    promotable: %{
      assignable_survey_tool: %{
        subject_count: target_subject_count
      }
    } = assignment
  }, Link.Dashboard, _user, url_resolver) do
    tag = Submission.get_tag(submission)

    target_subject_count =
      if target_subject_count == nil do
        0
      else
        target_subject_count
      end

    open_spot_count = Assignment.Context.open_spot_count(assignment)

    subtitle =
      get_content_list_item_subtitle(
        submission,
        promotion_content_node,
        open_spot_count,
        target_subject_count
      )

    quick_summary = get_quick_summary(updated_at)
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: url_resolver.(Systems.Campaign.ContentPage, id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
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

  defp tag(nil), do: %{text: dgettext("eyra-marketplace", "assignment.status.expired.label"), type: :disabled}

  defp tag(%{status: status} = _task) do
    case status do
      :pending -> %{text: dgettext("eyra-marketplace", "assignment.status.pending.label"), type: :warning}
      :completed -> %{text: dgettext("eyra-marketplace", "assignment.status.completed.label"), type: :tertiary}
      :accepted -> %{text: dgettext("eyra-marketplace", "assignment.status.accepted.label"), type: :success}
      :rejected -> %{text: dgettext("eyra-marketplace", "assignment.status.rejected.label"), type: :delete}
      _ -> %{text: "?", type: :disabled}
    end
  end

  defp subtitle(%{status: status} = _task, reward_value) do
    case status do
      :pending -> dgettext("eyra-marketplace", "assignment.status.pending.subtitle")
      :completed -> dgettext("eyra-marketplace", "assignment.status.completed.subtitle")
      :accepted -> dngettext("eyra-marketplace", "Awarded 1 credit", "Awarded %{count} credits", reward_value)
      :rejected -> dgettext("eyra-marketplace", "assignment.status.rejected.subtitle")
      _ ->  dgettext("eyra-marketplace", "reward.label", value: reward_value)
    end
  end

  defp get_quick_summary(updated_at) do
    updated_at
    |> CoreWeb.UI.Timestamp.apply_timezone()
    |> CoreWeb.UI.Timestamp.humanize()
  end

  defp get_content_list_item_subtitle(
         submission,
         promotion_content_node,
         open_spot_count,
         target_subject_count
       ) do
    case submission.status do
      :idle ->
        if Nodes.ready?(promotion_content_node) do
          dgettext("eyra-submission", "ready.for.submission.message")
        else
          dgettext("eyra-submission", "incomplete.forms.message")
        end

      :submitted ->
        dgettext("eyra-submission", "waiting.for.coordinator.message")

      :accepted ->
        case Submission.published_status(submission) do
          :scheduled ->
            dgettext("eyra-submission", "accepted.scheduled.message")

          :online ->
            dgettext("link-dashboard", "quick_summary.%{open_spot_count}.%{target_subject_count}",
              open_spot_count: open_spot_count,
              target_subject_count: target_subject_count
            )

          :closed ->
            dgettext("eyra-submission", "accepted.closed.message")
        end
    end
  end
end
