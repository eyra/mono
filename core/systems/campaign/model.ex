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
    Assignment,
    Pool
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
  def promotable(%{id: id}), do: raise("no promotable object available for campaign #{id}")

  def preload_graph(:full) do
    [
      auth_node: [:role_assignments],
      authors: [:user],
      promotion: [submission: [:criteria, :pool]],
      promotable_assignment: Assignment.Model.preload_graph(:full)
    ]
  end

  def preload_graph(_), do: []

  def author_as_string(%{authors: nil}), do: "?"
  def author_as_string(%{authors: []}), do: "?"

  def author_as_string(%{authors: [author | _]}) do
    author_as_string(author)
  end

  def author_as_string(%{displayname: displayname}), do: displayname
  def author_as_string(%{fullname: fullname}), do: fullname
end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Campaign.Model do
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Promotion,
    Assignment,
    Crew,
    Pool
  }

  alias Core.ImageHelpers

  def view_model(%Campaign.Model{} = campaign, page, user, url_resolver) do
    campaign
    |> Campaign.Model.flatten()
    |> vm(page, user, url_resolver)
  end

  defp vm(
         %{
           id: id,
           promotion: %{
             title: title,
             image_id: image_id
           },
           promotable:
             %{
               crew: crew
             } = assignment
         },
         {Link.Marketplace, _},
         user,
         url_resolver
       ) do
    task = task(crew, user)
    tag = tag(task)
    subtitle = subtitle(task, user, assignment)

    quick_summary =
      case task do
        %{updated_at: updated_at} ->
          updated_at
          |> CoreWeb.UI.Timestamp.apply_timezone()
          |> CoreWeb.UI.Timestamp.humanize()

        _ ->
          "?"
      end

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      id: id,
      path: url_resolver.(Assignment.LandingPage, id: assignment.id),
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end

  defp vm(
         %{
           id: id,
           updated_at: updated_at,
           promotion:
             %{
               title: title,
               image_id: image_id,
               submission: submission
             } = promotion,
           promotable:
             %{
               assignable_experiment: %{
                 subject_count: target_subject_count
               }
             } = assignment
         },
         {Link.Console, :content},
         _user,
         url_resolver
       ) do
    path = url_resolver.(Systems.Campaign.ContentPage, id: id)
    tag = Pool.Context.get_tag(submission)

    promotion_ready? = Promotion.Context.ready?(promotion)

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
        promotion_ready?,
        open_spot_count,
        target_subject_count
      )

    quick_summary = get_quick_summary(updated_at)
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: path,
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end

  defp vm(
         %{
           promotion: %{
             title: title,
             image_id: image_id
           },
           promotable:
             %{
               crew: crew
             } = assignment
         },
         {Link.Console, :contribution},
         user,
         url_resolver
       ) do
    %{updated_at: updated_at} = task = task(crew, user)
    path = url_resolver.(Systems.Assignment.LandingPage, id: assignment.id)
    tag = tag(task)
    subtitle = subtitle(task, user, assignment)
    quick_summary = get_quick_summary(updated_at)
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: path,
      title: title,
      subtitle: subtitle,
      tag: tag,
      level: :critical,
      image: image,
      quick_summary: quick_summary
    }
  end

  defp task(crew, user) do
    case Crew.Context.get_member!(crew, user) do
      nil -> nil
      member -> Crew.Context.get_task(crew, member)
    end
  end

  defp tag(nil),
    do: %{text: dgettext("eyra-marketplace", "assignment.status.expired.label"), type: :disabled}

  # defp tag(%{expired: true} = _task), do: %{text: dgettext("eyra-marketplace", "assignment.status.expired.label"), type: :disabled}

  defp tag(%{status: status} = _task) do
    case status do
      :pending ->
        %{text: dgettext("eyra-marketplace", "assignment.status.pending.label"), type: :warning}

      :completed ->
        %{
          text: dgettext("eyra-marketplace", "assignment.status.completed.label"),
          type: :tertiary
        }

      :accepted ->
        %{text: dgettext("eyra-marketplace", "assignment.status.accepted.label"), type: :success}

      :rejected ->
        %{text: dgettext("eyra-marketplace", "assignment.status.rejected.label"), type: :delete}

      _ ->
        %{text: "?", type: :disabled}
    end
  end

  defp subtitle(nil, _, _), do: "?"

  defp subtitle(
         %{status: status} = _task,
         %{id: user_id} = _user,
         %{id: assignment_id} = _assignment
       ) do
    case status do
      :pending ->
        dgettext("eyra-marketplace", "assignment.status.pending.subtitle")

      :completed ->
        dgettext("eyra-marketplace", "assignment.status.completed.subtitle")

      :accepted ->
        rewarded_value = Campaign.Context.rewarded_value(assignment_id, user_id)

        dngettext(
          "eyra-marketplace",
          "Awarded 1 credit",
          "Awarded %{count} credits",
          rewarded_value
        )

      :rejected ->
        dgettext("eyra-marketplace", "assignment.status.rejected.subtitle")

      _ ->
        dgettext("eyra-marketplace", "reward.label", value: 0)
    end
  end

  defp get_quick_summary(updated_at) do
    updated_at
    |> CoreWeb.UI.Timestamp.apply_timezone()
    |> CoreWeb.UI.Timestamp.humanize()
  end

  defp get_content_list_item_subtitle(
         submission,
         promotion_ready?,
         open_spot_count,
         target_subject_count
       ) do
    case submission.status do
      :idle ->
        if promotion_ready? do
          dgettext("eyra-submission", "ready.for.submission.message")
        else
          dgettext("eyra-submission", "incomplete.forms.message")
        end

      :submitted ->
        dgettext("eyra-submission", "waiting.for.coordinator.message")

      :accepted ->
        case Pool.Context.published_status(submission) do
          :scheduled ->
            dgettext("eyra-submission", "accepted.scheduled.message")

          :released ->
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
