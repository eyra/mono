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

    many_to_many(:submissions, Pool.SubmissionModel,
      join_through: Campaign.SubmissionModel,
      join_keys: [campaign_id: :id, submission_id: :id]
    )

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
    |> Map.put(:submission, submission(campaign))
  end

  def promotable(%{promotable_assignment: promotable}) when not is_nil(promotable), do: promotable
  def promotable(%{id: id}), do: raise("no promotable object available for campaign #{id}")

  def submission(%{submissions: [submission]}), do: submission
  def submission(%{submissions: []}), do: nil
  def submission(_), do: raise("No support for multiple submissions yet")

  def preload_graph(:full) do
    [
      :promotion,
      auth_node: [:role_assignments],
      authors: [:user],
      submissions: [:criteria, pool: Pool.Model.preload_graph(:full)],
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
    Pool,
    Budget
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
           submission: submission,
           promotion: %{
             id: open_id,
             title: title,
             image_id: image_id,
             themes: themes,
             marks: marks
           },
           promotable:
             %{
               assignable_experiment: %{
                 duration: duration,
                 language: language
               }
             } = assignment
         },
         {Link.Marketplace, :card},
         _user,
         _url_resolver
       ) do
    duration = if duration === nil, do: 0, else: duration

    reward_value_label = reward_value_label(submission)
    reward_label = dgettext("eyra-submission", "reward.title")
    duration_label = dgettext("eyra-promotion", "duration.title")

    info1_elements = [
      "#{duration_label}: #{duration} min.",
      "#{reward_label}: #{reward_value_label}"
    ]

    info1_elements =
      if language != nil do
        language_label = language |> String.upcase(:ascii)
        info1_elements ++ ["#{language_label}"]
      else
        info1_elements
      end

    info1 = Enum.join(info1_elements, " | ")
    info = [info1]

    open? = Assignment.Context.open?(assignment)

    label =
      if open? do
        nil
      else
        %{text: dgettext("eyra-marketplace", "assignment.status.complete.label"), type: :tertiary}
      end

    icon_url = get_card_icon_url(marks)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_card_tags(themes)

    %{
      id: id,
      edit_id: id,
      open_id: open_id,
      title: title,
      image_info: image_info,
      tags: tags,
      duration: duration,
      info: info,
      icon_url: icon_url,
      label: label
    }
  end

  defp vm(
         %{
           id: id,
           submission: submission,
           promotion: %{
             id: open_id,
             title: title,
             image_id: image_id,
             themes: themes,
             marks: marks
           },
           promotable:
             %{
               assignable_experiment: %{
                 duration: duration,
                 language: language
               }
             } = assignment
         },
         {Campaign.OverviewPage, :card},
         _user,
         _url_resolver
       ) do
    duration = if duration === nil, do: 0, else: duration

    open_spot_count = Assignment.Context.open_spot_count(assignment)

    duration_label = dgettext("eyra-promotion", "duration.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")

    reward_label = dgettext("eyra-submission", "reward.title")
    reward_value_label = reward_value_label(submission)

    info1_elements = [
      "#{duration_label}: #{duration} min.",
      "#{reward_label}: #{reward_value_label}"
    ]

    info1_elements =
      if language != nil do
        language_label = language |> String.upcase(:ascii)
        info1_elements ++ ["#{language_label}"]
      else
        info1_elements
      end

    info1 = Enum.join(info1_elements, " | ")
    info2 = "#{open_spots_label}"

    info = [info1, info2]

    label = Pool.Context.get_tag(submission)
    icon_url = get_card_icon_url(marks)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_card_tags(themes)
    type = get_card_type(submission)

    %{
      type: type,
      id: id,
      edit_id: id,
      open_id: open_id,
      title: title,
      image_info: image_info,
      tags: tags,
      duration: duration,
      info: info,
      icon_url: icon_url,
      label: label,
      label_type: "secondary",
      left_actions: [
        %{
          action: %{type: :send, event: "share", item: "#{id}"},
          face: %{
            type: :label,
            label: dgettext("eyra-ui", "share.button"),
            font: "text-subhead font-subhead",
            text_color: "text-white",
            wrap: true
          }
        },
        %{
          action: %{type: :send, event: "duplicate", item: id},
          face: %{
            type: :label,
            label: dgettext("eyra-ui", "duplicate.button"),
            font: "text-subhead font-subhead",
            text_color: "text-white",
            wrap: true
          }
        }
      ],
      right_actions: [
        %{
          action: %{type: :send, event: "delete", item: id},
          face: %{type: :icon, icon: :delete, color: :white}
        }
      ]
    }
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
           submission: submission,
           promotion:
             %{
               title: title,
               image_id: image_id
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
         %{promotable: assignment} = campaign,
         {Link.Console, :contribution},
         user,
         url_resolver
       ) do
    path = url_resolver.(Systems.Assignment.LandingPage, id: assignment.id)
    vm(campaign, :contribution, user, path)
  end

  defp vm(
         %{submission: submission} = campaign,
         {Pool.StudentPage, :contribution},
         user,
         url_resolver
       ) do
    # FIXME: POOL adapt to multiple submissions
    path = url_resolver.(Systems.Pool.SubmissionPage, id: submission.id)
    vm(campaign, :contribution, user, path)
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
         :contribution,
         user,
         path
       ) do
    %{updated_at: updated_at} = task = task(crew, user)
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
         user,
         assignment
       ) do
    case status do
      :pending ->
        dgettext("eyra-marketplace", "assignment.status.pending.subtitle")

      :completed ->
        dgettext("eyra-marketplace", "assignment.status.completed.subtitle")

      :accepted ->
        rewarded_amount = Campaign.Context.rewarded_amount(assignment, user)

        dngettext(
          "eyra-marketplace",
          "Awarded 1 credit",
          "Awarded %{count} credits",
          rewarded_amount
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
         nil,
         promotion_ready?,
         open_spot_count,
         target_subject_count
       ) do
    get_content_list_item_subtitle(
      %{status: :idle},
      promotion_ready?,
      open_spot_count,
      target_subject_count
    )
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

      :completed ->
        dgettext("eyra-submission", "submission.completed.message")
    end
  end

  defp reward_value_label(%Pool.SubmissionModel{
         pool: %{currency: currency},
         reward_value: reward_value
       }) do
    reward_value_label(currency, reward_value)
  end

  defp reward_value_label(_), do: "?"

  defp reward_value_label(%{} = currency, nil), do: reward_value_label(currency, 0)

  defp reward_value_label(%{} = currency, reward_value) when is_integer(reward_value) do
    locale = Gettext.get_locale(CoreWeb.Gettext)
    Budget.CurrencyModel.label(currency, locale, reward_value)
  end

  def get_card_type(submission) do
    case completed?(submission) do
      true -> :secondary
      false -> :primary
    end
  end

  def get_card_tags(nil), do: []

  def get_card_tags(themes) do
    themes
    |> Enum.map(&Core.Enums.Themes.translate(&1))
  end

  def get_card_icon_url(marks) do
    case marks do
      [mark] -> CoreWeb.Endpoint.static_path("/images/#{mark}.svg")
      _ -> nil
    end
  end

  defp completed?(%{status: status} = submission) do
    case status do
      :completed -> true
      :accepted -> Pool.Context.published_status(submission) == :closed
      _ -> false
    end
  end
end
