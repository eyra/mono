defmodule Link.Marketplace.Card do
  alias Core.Pools.Submission
  alias Core.ImageHelpers

  import CoreWeb.Gettext

  alias Systems.{
    Assignment
  }

  def primary_campaign(
        %{
          id: id,
          promotion: %{
            id: open_id,
            title: title,
            image_id: image_id,
            themes: themes,
            marks: marks
          },
          promotable_assignment: %{
            assignable_lab_tool: %{
              id: edit_id
              # time_slots: time_slots,
              # subject_count: subject_count,
            }
          }
        },
        socket
      ) do
    reward_value = 0
    reward_currency = :eur
    duration = 0

    reward_string = CurrencyFormatter.format(reward_value, reward_currency, keep_decimals: true)

    duration_label = dgettext("eyra-promotion", "duration.title")
    reward_label = dgettext("eyra-promotion", "reward.title")

    info = [
      "#{duration_label}: #{duration} min. | #{reward_label}: #{reward_string}"
    ]

    label = nil

    icon_url = get_icon_url(marks, socket)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_tags(themes)

    %{
      id: id,
      edit_id: edit_id,
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

  def primary_campaign(
        %{
          id: id,
          promotion: %{
            id: open_id,
            title: title,
            image_id: image_id,
            themes: themes,
            marks: marks,
            submission: submission
          },
          promotable_assignment:
            %{
              assignable_experiment: %{
                duration: duration,
                language: language
              }
            } = assignment
        },
        socket
      ) do
    duration = if duration === nil, do: 0, else: duration

    reward_label = dgettext("eyra-submission", "reward.title")
    duration_label = dgettext("eyra-promotion", "duration.title")

    info1_elements = [
      "#{duration_label}: #{duration} min.",
      "#{reward_label}: #{submission.reward_value}"
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

    icon_url = get_icon_url(marks, socket)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_tags(themes)

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

  def campaign_researcher(
        %{
          id: id,
          promotion: %{
            id: open_id,
            title: title,
            image_id: image_id,
            themes: themes,
            marks: marks,
            submission: submission
          },
          promotable_assignment:
            %{
              assignable_experiment: %{
                duration: duration,
                language: language
              }
            } = assignment
        },
        socket
      ) do
    duration = if duration === nil, do: 0, else: duration

    open_spot_count = Assignment.Context.open_spot_count(assignment)

    reward_label = dgettext("eyra-submission", "reward.title")
    duration_label = dgettext("eyra-promotion", "duration.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")

    info1_elements = [
      "#{duration_label}: #{duration} min.",
      "#{reward_label}: #{submission.reward_value}"
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

    label = get_label(assignment, submission)
    icon_url = get_icon_url(marks, socket)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_tags(themes)
    type = get_type(submission)

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

  # lab study
  def campaign_researcher(
        %{
          id: id,
          lab_tool: %{
            promotion: %{
              id: open_id,
              title: title,
              image_id: image_id,
              themes: themes,
              marks: marks,
              submission: submission
            }
          }
        },
        socket
      ) do
    label = nil
    icon_url = get_icon_url(marks, socket)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_tags(themes)
    type = get_type(submission)

    %{
      type: type,
      id: id,
      edit_id: id,
      open_id: open_id,
      title: title,
      image_info: image_info,
      tags: tags,
      duration: "-",
      info: ["-"],
      icon_url: icon_url,
      label: label,
      label_type: "secondary"
    }
  end

  defp get_label(assignment, submission) do
    open? = Assignment.Context.open?(assignment)

    if open? or submission.status != :accepted do
      get_label(submission)
    else
      %{text: dgettext("eyra-marketplace", "assignment.status.complete.label"), type: :disabled}
    end
  end

  defp get_label(submission) do
    case submission.status do
      :idle ->
        %{text: dgettext("eyra-submission", "status.idle.label"), type: :tertiary}

      :submitted ->
        %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

      :accepted ->
        case Submission.published_status(submission) do
          :scheduled ->
            %{
              text: dgettext("eyra-submission", "status.accepted.scheduled.label"),
              type: :tertiary
            }

          :online ->
            %{text: dgettext("eyra-submission", "status.accepted.online.label"), type: :success}

          :closed ->
            %{
              text: dgettext("eyra-submission", "status.accepted.closed.label"),
              type: :disabled
            }
        end
    end
  end

  defp closed?(%{status: status} = submission) do
    case status do
      :accepted -> Submission.published_status(submission) == :closed
      _ -> false
    end
  end

  def get_type(submission) do
    case closed?(submission) do
      true -> :secondary
      false -> :primary
    end
  end

  def get_tags(nil), do: []

  def get_tags(themes) do
    themes
    |> Enum.map(&Core.Enums.Themes.translate(&1))
  end

  def get_icon_url(marks, socket) do
    case marks do
      [mark] -> CoreWeb.Endpoint.static_path("/images/#{mark}.svg")
      _ -> nil
    end
  end
end
