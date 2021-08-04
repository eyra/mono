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
              marks: marks,
              published_at: published_at
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

    label =
      if published_at === nil, do: dgettext("eyra-promotion", "published.false.label"), else: nil

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
              reward_currency: reward_currency,
              reward_value: reward_value,
              promotion: %{
                id: open_id,
                title: title,
                image_id: image_id,
                themes: themes,
                marks: marks,
                published_at: published_at
              }
            } = tool
        },
        socket
      ) do
    subject_count = if subject_count === nil, do: 0, else: subject_count
    reward_value = if reward_value === nil, do: 0, else: reward_value
    reward_currency = if reward_currency === nil, do: :eur, else: reward_currency
    duration = if duration === nil, do: 0, else: duration

    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = subject_count - occupied_spot_count

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

    label =
      if published_at === nil, do: dgettext("eyra-promotion", "published.false.label"), else: nil

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

  def get_tags(nil), do: []

  def get_tags(themes) do
    themes
    |> Enum.map(&Core.Themes.translate(&1))
  end

  def get_icon_url(marks, socket) do
    case marks do
      [mark] -> Routes.static_path(socket, "/images/#{mark}.svg")
      _ -> nil
    end
  end
end
