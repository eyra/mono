defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Advert.Model do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  import Frameworks.Utility.Guards

  alias Systems.{
    Advert,
    Promotion,
    Assignment,
    Pool,
    Budget
  }

  alias Core.ImageHelpers

  def view_model(%Advert.Model{} = advert, page, %{current_user: user}) do
    vm(advert, page, user)
  end

  defp vm(
         %{
           id: id,
           submission: submission,
           promotion: %{
             id: promotion_id,
             title: title,
             image_id: image_id,
             themes: themes,
             marks: marks
           },
           assignment:
             %{
               info: %{
                 duration: duration,
                 language: language
               }
             } = assignment
         },
         {Next.Console, :card},
         %{uri_path: uri_path}
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

    has_open_spots? = Assignment.Public.has_open_spots?(assignment)

    label =
      if has_open_spots? do
        nil
      else
        %{text: dgettext("eyra-marketplace", "assignment.status.complete.label"), type: :tertiary}
      end

    icon_url = get_card_icon_url(marks)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_card_tags(themes)

    %{
      id: id,
      path: ~p"/promotion/#{promotion_id}?back=#{uri_path}",
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
             title: title,
             image_id: image_id,
             themes: themes,
             marks: marks
           },
           assignment:
             %{
               info: %{
                 duration: duration,
                 language: language
               }
             } = assignment
         },
         {Advert.OverviewPage, :card},
         _assigns
       ) do
    duration = if duration === nil, do: 0, else: duration

    open_spot_count = Assignment.Public.open_spot_count(assignment)

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

    label = Pool.Public.get_tag(submission)
    icon_url = get_card_icon_url(marks)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_card_tags(themes)
    type = get_card_type(submission)
    action_icon_color = get_action_icon_color(type)
    action_label_color = get_action_label_color(type)

    left_actions =
      if Pool.SubmissionModel.concept?(submission) do
        [
          %{
            action: %{type: :send, event: "delete", item: id},
            face: %{type: :icon, icon: :delete, color: action_icon_color}
          }
        ]
      else
        []
      end

    %{
      type: type,
      id: id,
      path: ~p"/advert/#{id}/content",
      title: title,
      image_info: image_info,
      tags: tags,
      duration: duration,
      info: info,
      icon_url: icon_url,
      label: label,
      label_type: "secondary",
      right_actions: [
        %{
          action: %{type: :send, event: "duplicate", item: id},
          face: %{
            type: :label,
            label: dgettext("eyra-ui", "duplicate.button"),
            font: "text-subhead font-subhead",
            text_color: action_label_color,
            wrap: true
          }
        },
        %{
          action: %{type: :send, event: "share", item: "#{id}"},
          face: %{
            type: :label,
            label: dgettext("eyra-ui", "share.button"),
            font: "text-subhead font-subhead",
            text_color: action_label_color,
            wrap: true
          }
        }
      ],
      left_actions: left_actions
    }
  end

  defp vm(
         %{
           id: id,
           promotion: %{
             title: title,
             image_id: image_id
           },
           assignment: assignment
         },
         {Next.Marketplace, _},
         %{current_user: user}
       ) do
    status = Assignment.Public.status(assignment, user)
    tag = tag(status)
    subtitle = subtitle(status, user, assignment)

    timestamp = Assignment.Public.timestamp(assignment, user)
    quick_summary = get_quick_summary(timestamp)

    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      id: id,
      path: ~p"/assignment/#{assignment.id}/landing",
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
           assignment:
             %{
               info: %{
                 subject_count: target_subject_count
               }
             } = assignment
         },
         {Next.Console.Page, :content},
         _assigns
       ) do
    tag = Pool.Public.get_tag(submission)

    promotion_ready? = Promotion.Public.ready?(promotion)

    target_subject_count =
      if target_subject_count == nil do
        0
      else
        target_subject_count
      end

    open_spot_count = Assignment.Public.open_spot_count(assignment)

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
      path: ~p"/advert/#{id}/content",
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
           promotion: %{
             title: title,
             image_id: image_id
           }
         } = advert,
         {Budget.FundingPage, :budget_adverts},
         _assigns
       ) do
    path = ~p"/advert/#{id}/content?tab=#{:funding}"
    tag = funding_tag(advert)
    subtitle = required_funding(advert)
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
         %{assignment: assignment} = advert,
         {Next.Console.Page, :contribution},
         user
       ) do
    path = ~p"/assignment/#{assignment.id}/landing"
    vm(advert, :contribution, user, path)
  end

  defp vm(
         %{submission: submission} = advert,
         {Pool.ParticipantPage, :contribution},
         user
       ) do
    path = ~p"/pool/advert/#{submission.id}"
    vm(advert, :contribution, user, path)
  end

  defp vm(
         %{
           promotion: %{
             title: title,
             image_id: image_id
           },
           assignment: assignment
         },
         :contribution,
         user,
         path
       ) do
    status = Assignment.Public.status(assignment, user)
    tag = tag(status)
    subtitle = subtitle(status, user, assignment)
    timestamp = Assignment.Public.timestamp(assignment, user)
    quick_summary = get_quick_summary(timestamp)
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

  defp required_funding(%{
         submission: %{reward_value: reward_value, pool: %{currency: currency}},
         assignment: %{assignable_inquiry: %{subject_count: subject_count}}
       }) do
    reward_value = guard_nil(reward_value, :integer)
    subject_count = guard_nil(subject_count, :integer)

    locale = Gettext.get_locale(CoreWeb.Gettext)
    required_funding_amount = subject_count * reward_value
    required_funding_label = Budget.CurrencyModel.label(currency, locale, required_funding_amount)
    dgettext("eyra-advert", "required.funding.label", funding: required_funding_label)
  end

  defp funding_tag(%{
         submission: %{reward_value: reward_value},
         assignment: %{budget: budget, assignable_inquiry: %{subject_count: subject_count}}
       }) do
    reward_value = guard_nil(reward_value, :integer)
    subject_count = guard_nil(subject_count, :integer)

    available = Budget.Model.amount_available(budget)

    if available < reward_value do
      %{text: dgettext("eyra-advert", "funding.status.broke.label"), type: :error}
    else
      if available >= subject_count * reward_value do
        %{text: dgettext("eyra-advert", "funding.status.rich.label"), type: :success}
      else
        %{text: dgettext("eyra-advert", "funding.status.poor.label"), type: :warning}
      end
    end
  end

  defp tag(status) do
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
    end
  end

  defp subtitle(
         status,
         user,
         assignment
       ) do
    case status do
      :pending ->
        dgettext("eyra-marketplace", "assignment.status.pending.subtitle")

      :completed ->
        dgettext("eyra-marketplace", "assignment.status.completed.subtitle")

      :accepted ->
        rewarded_amount = Advert.Public.rewarded_amount(assignment, user)

        dngettext(
          "eyra-marketplace",
          "Awarded 1 credit",
          "Awarded %{count} credits",
          rewarded_amount
        )

      :rejected ->
        dgettext("eyra-marketplace", "assignment.status.rejected.subtitle")
    end
  end

  defp get_quick_summary(nil), do: "?"

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
        case Pool.Public.published_status(submission) do
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
    case inactive?(submission) do
      true -> :secondary
      false -> :primary
    end
  end

  def get_action_label_color(type) do
    case type do
      :primary -> "text-white"
      :secondary -> "text-grey1"
    end
  end

  def get_action_icon_color(type) do
    case type do
      :primary -> :light
      :secondary -> :dark
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

  defp inactive?(%{status: status} = submission) do
    case status do
      :completed -> true
      :accepted -> Pool.Public.published_status(submission) == :closed
      _ -> false
    end
  end
end
