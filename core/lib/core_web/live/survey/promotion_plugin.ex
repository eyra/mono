defmodule CoreWeb.Survey.PromotionPlugin do
  import CoreWeb.Gettext

  alias Core.Studies
  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.Survey.Tools

  alias CoreWeb.Promotion.Plugin

  @behaviour Plugin

  @impl Plugin
  def info(promotion_id, %{assigns: %{current_user: user}} = _socket) do
    tool = Tools.get_by_promotion(promotion_id)
    call_to_action = get_call_to_action(tool, user)
    byline = get_byline(tool)
    highlights = get_highlights(tool)

    %{
      call_to_action: call_to_action,
      highlights: highlights,
      devices: tool.devices,
      byline: byline
    }
  end

  @impl Plugin
  def get_cta_path(promotion_id, "apply", %{assigns: %{current_user: user}} = _socket) do
    tool = Tools.get_by_promotion(promotion_id)
    Tools.apply_participant(tool, user)
    Tools.get_or_create_task(tool, user)
    tool.survey_url
  end

  @impl Plugin
  def get_cta_path(promotion_id, "open", _socket) do
    tool = Tools.get_by_promotion(promotion_id)
    tool.survey_url
  end

  defp get_call_to_action(tool, user) do
    case Tools.participant?(tool, user) do
      false ->
        %CallToAction{
          label: dgettext("eyra-survey", "apply.cta.title"),
          target: %Target{type: :event, value: "apply"}
        }

      true ->
        %CallToAction{
          label: dgettext("eyra-survey", "open.cta.title"),
          target: %Target{type: :event, value: "open"}
        }
    end
  end

  defp get_byline(tool) do
    authors =
      Studies.get_study!(tool.study_id)
      |> Studies.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("eyra-survey", "by.author.label")}: " <> authors
  end

  defp get_highlights(tool) do
    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = tool.subject_count - occupied_spot_count

    spots_title = dgettext("eyra-survey", "spots.highlight.title")
    spots_text = "Nog #{open_spot_count} van #{tool.subject_count}"

    available_title = dgettext("eyra-survey", "available.highlight.title")

    available_text =
      dgettext("eyra-survey", "available.future.highlight.text",
        from: "15 june",
        till: "15 augustus 2021"
      )

    reward_title = dgettext("eyra-survey", "reward.highlight.title")

    reward_text =
      CurrencyFormatter.format(tool.reward_value, tool.reward_currency, keep_decimals: true)

    [
      %{title: available_title, text: available_text},
      %{title: spots_title, text: spots_text},
      %{title: reward_title, text: reward_text}
    ]
  end
end
