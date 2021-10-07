defmodule Link.Survey.PromotionPlugin do
  import CoreWeb.Gettext

  alias Core.Studies
  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.Survey.Tools
  alias Core.Survey.Tool

  alias CoreWeb.Promotion.Plugin

  @behaviour Plugin

  @impl Plugin
  def info(promotion_id, %{assigns: %{current_user: user}} = _socket) do
    tool = Tools.get_by_promotion(promotion_id)
    call_to_action = get_call_to_action(tool, user)
    byline = get_byline(tool)
    highlights = get_highlights(tool)

    languages =
      if tool.language != nil do
        [tool.language]
      else
        nil
      end |> IO.inspect(label: "LANGUAGES")

    %{
      call_to_action: call_to_action,
      highlights: highlights,
      devices: tool.devices,
      languages: languages,
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
  def get_cta_path(promotion_id, "open", %{assigns: %{current_user: user}}) do
    tool = Tools.get_by_promotion(promotion_id)
    Tool.prepare_url(
      tool.survey_url,
      %{"participantId"=> Tools.participant_id(tool, user)}
    )
  end

  defp get_call_to_action(tool, user) do
    if Tools.participant?(tool, user) do
      %CallToAction{
        label: dgettext("link-survey", "open.cta.title"),
        target: %Target{type: :event, value: "open"}
      }
    else
      %CallToAction{
        label: dgettext("link-survey", "apply.cta.title"),
        target: %Target{type: :event, value: "apply"}
      }
    end
  end

  defp get_byline(tool) do
    authors =
      Studies.get_study!(tool.study_id)
      |> Studies.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("link-survey", "by.author.label")}: " <> authors
  end

  defp get_highlights(%{subject_count: subject_count, duration: duration} = tool) do
    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = if subject_count do subject_count - occupied_spot_count else 0 end

    spots_title = dgettext("link-survey", "spots.highlight.title")
    spots_text = dgettext("link-survey", "spots.highlight.text", open: open_spot_count, total: subject_count)

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    reward_title = dgettext("link-survey", "reward.highlight.title")

    # reward_text =
    #   CurrencyFormatter.format(tool.reward_value, tool.reward_currency, keep_decimals: true)

    reward_text = "? credits"

    [
      %{title: duration_title, text: duration_text},
      %{title: reward_title, text: reward_text},
      %{title: spots_title, text: spots_text},
    ]
  end
end
