defmodule CoreWeb.ViewModel.Card do
  alias Core.SurveyTools
  alias Core.DataDonation
  alias Core.ImageHelpers
  alias CoreWeb.Router.Helpers, as: Routes
  import CoreWeb.Gettext

  def primary_study(
        %{
          id: id,
          title: title,
          survey_tools: [
            %{
              subject_count: subject_count,
              image_id: image_id,
              themes: themes,
              duration: duration,
              reward_currency: reward_currency,
              reward_value: reward_value,
              marks: marks,
              published_at: published_at
            } = survey_tool
          ]
        },
        socket
      ) do
    subject_count = if subject_count === nil, do: 0, else: subject_count
    reward_value = if reward_value === nil, do: 0, else: reward_value
    reward_currency = if reward_currency === nil, do: :eur, else: reward_currency
    duration = if duration === nil, do: 0, else: duration

    occupied_spot_count = SurveyTools.count_tasks(survey_tool, [:pending, :completed])
    open_spot_count = subject_count - occupied_spot_count

    reward_string = CurrencyFormatter.format(reward_value, reward_currency, keep_decimals: true)

    duration_label = dgettext("eyra-survey", "duration.title")
    reward_label = dgettext("eyra-survey", "reward.title")
    open_spots_label = dgettext("eyra-survey", "open.spots.label", count: "#{open_spot_count}")
    deadline_label = dgettext("eyra-survey", "deadline.label", days: "3")

    info = [
      "#{duration_label}: #{duration} min. | #{reward_label}: #{reward_string}",
      "#{open_spots_label}",
      "#{deadline_label}"
    ]

    label =
      if published_at === nil, do: dgettext("eyra-survey", "published.false.label"), else: nil

    icon_url = get_icon_url(marks, socket)
    image_info = ImageHelpers.get_image_info(image_id)
    tags = get_tags(themes)

    %{
      id: id,
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
          data_donation_tool: %{
              script: _script,
              subject_count: subject_count,
              reward_currency: reward_currency,
              reward_value: reward_value,
              promotion: %{
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

    occupied_spot_count = DataDonation.Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = subject_count - occupied_spot_count

    reward_string = CurrencyFormatter.format(reward_value, reward_currency, keep_decimals: true)

    reward_label = dgettext("eyra-promotion", "reward.title")
    open_spots_label = dgettext("eyra-promotion", "open.spots.label", count: "#{open_spot_count}")
    deadline_label = dgettext("eyra-promotion", "deadline.label", days: "3")

    info = [
      "#{reward_label}: #{reward_string}",
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
      title: title,
      image_info: image_info,
      tags: tags,
      duration: nil,
      info: info,
      icon_url: icon_url,
      label: label
    }
  end

  def primary_study(
        %{
          id: id,
          title: title
        },
        socket
      ) do
    %{
      id: id,
      title: title,
      label: nil,
      image_info: ImageHelpers.get_image_info(nil),
      tags: [],
      duration: nil,
      info: [],
      icon_url: Routes.static_path(socket, "/images/eyra-icon.svg")
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
