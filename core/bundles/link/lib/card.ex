defmodule Link.Marketplace.Card do
  alias Core.Survey.Tools
  alias Core.ImageHelpers
  alias CoreWeb.Router.Helpers, as: Routes
  import CoreWeb.Gettext

  def primary_study(
        %{
          id: id,
          lab_tool: %{
            id: edit_id,
            # time_slots: time_slots,
            # subject_count: subject_count,
            promotion: %{
              id: open_id,
              title: title,
              image_id: image_id,
              themes: themes,
              marks: marks
            }
          }
        },
        socket
      ) do
    reward_value = 0
    reward_currency = :eur
    duration = 0

    occupied_spot_count = 0
    open_spot_count = 0 - occupied_spot_count

    reward_string = CurrencyFormatter.format(reward_value, reward_currency, keep_decimals: true)

    duration_label = dgettext("eyra-promotion", "duration.title")
    reward_label = dgettext("eyra-promotion", "reward.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")
    deadline_label = dgettext("eyra-promotion", "deadline.label", days: "3")

    info = [
      "#{duration_label}: #{duration} min. | #{reward_label}: #{reward_string}",
      "#{open_spots_label}",
      "#{deadline_label}"
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

  def primary_study(
        %{
          id: id,
          survey_tool:
            %{
              id: edit_id,
              duration: duration,
              subject_count: subject_count,
              promotion: %{
                id: open_id,
                title: title,
                image_id: image_id,
                themes: themes,
                marks: marks
              }
            } = tool
        },
        socket
      ) do
    subject_count = if subject_count === nil, do: 0, else: subject_count
    duration = if duration === nil, do: 0, else: duration

    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = subject_count - occupied_spot_count

    duration_label = dgettext("eyra-promotion", "duration.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")

    info = [
      "#{duration_label}: #{duration} min.",
      "#{open_spots_label}"
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

  def primary_study_researcher(
        %{
          id: id,
          survey_tool:
            %{
              id: edit_id,
              duration: duration,
              subject_count: subject_count,
              promotion: %{
                id: open_id,
                title: title,
                image_id: image_id,
                themes: themes,
                marks: marks,
                submission: %{
                  status: status
                }
              }
            } = tool
        },
        socket
      ) do
    subject_count = if subject_count === nil, do: 0, else: subject_count
    duration = if duration === nil, do: 0, else: duration

    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = subject_count - occupied_spot_count

    duration_label = dgettext("eyra-promotion", "duration.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")

    info = [
      "#{duration_label}: #{duration} min.",
      "#{open_spots_label}"
    ]

    label =
      case status do
        :idle ->
          %{text: dgettext("eyra-submission", "status.idle.label"), type: :warning}

        :submitted ->
          %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

        :accepted ->
          %{text: dgettext("eyra-submission", "status.accepted.label"), type: :success}
      end

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
      label: label,
      label_type: "secondary"
    }
  end

  # lab study
  def primary_study_researcher(
        %{
          id: id,
          lab_tool: %{
            id: edit_id,
            promotion: %{
              id: open_id,
              title: title,
              image_id: image_id,
              themes: themes,
              marks: marks,
              submission: %{
                status: status
              }
            }
          }
        },
        socket
      ) do
    label =
      case status do
        :idle ->
          %{text: dgettext("eyra-submission", "status.idle.label"), type: :warning}

        :submitted ->
          %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

        :accepted ->
          %{text: dgettext("eyra-submission", "status.accepted.label"), type: :success}
      end

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
      duration: "-",
      info: ["-"],
      icon_url: icon_url,
      label: label,
      label_type: "secondary"
    }
  end

  def get_tags(nil), do: []

  def get_tags(themes) do
    themes
    |> Enum.map(&Core.Enums.Themes.translate(&1))
  end

  def get_icon_url(marks, socket) do
    case marks do
      [mark] -> Routes.static_path(socket, "/images/#{mark}.svg")
      _ -> nil
    end
  end
end
