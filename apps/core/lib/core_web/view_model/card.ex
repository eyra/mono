defmodule CoreWeb.ViewModel.Card do
  alias Core.SurveyTools
  alias CoreWeb.RoutesProxy, as: Routes

  import CoreWeb.Gettext

  def primary_study(
        %{
          id: id,
          title: title,
          survey_tools: [
            %{
              subject_count: subject_count,
              image_url: image_url,
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

    image_url =
      if image_url === nil,
        do:
          "https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=3900&q=80",
        else: image_url

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

    icon_url =
      case marks do
        [mark] -> Routes.static_path(socket, "/images/#{mark}.svg")
        _ -> nil
      end

    label =
      if published_at === nil, do: dgettext("eyra-survey", "published.false.label"), else: nil

    %{
      id: id,
      title: title,
      image_url: image_url,
      tags: themes,
      duration: duration,
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
      image_url:
        "https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=3900&q=80",
      tags: [],
      duration: nil,
      info: [],
      icon_url: Routes.static_path(socket, "/images/eyra-icon.svg")
    }
  end

  def secondary_study(%{
        id: id,
        title: title,
        survey_tools: [
          %{
            image_url: image_url
          }
        ]
      }) do
    %{
      id: id,
      title: title,
      image_url: image_url
    }
  end
end
