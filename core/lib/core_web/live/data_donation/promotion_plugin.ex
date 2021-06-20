defmodule CoreWeb.DataDonation.PromotionPlugin do

  import CoreWeb.Gettext

  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.DataDonation.Tools

  alias CoreWeb.Promotion.Plugin

  @behaviour Plugin

  @impl Plugin
  def info(promotion_id, %{assigns: %{current_user: user}} = _socket) do
    tool = Tools.get_by_promotion(promotion_id)
    call_to_action = get_call_to_action(tool, user)
    highlights = get_highlights(tool)

    %{
      call_to_action: call_to_action,
      highlights: highlights,
      devices: [:desktop]
    }
  end

  @impl Plugin
  def handle_event(_promotion_id, "apply", socket) do
    {:ok, socket}
  end

  @impl Plugin
  def handle_event(_promotion_id, "open", socket) do
    {:ok, socket}
  end

  defp get_call_to_action(tool, user) do

    case Tools.participant?(tool, user) do
      false ->
        %CallToAction{
          label: dgettext("eyra-data-donation", "apply.cta.title"),
          target: %Target{type: :event, value: "apply"}
         }
      true ->
        %CallToAction{
          label: dgettext("eyra-data-donation", "open.cta.title"),
          target: %Target{type: :event, value: "open"}
        }
    end

  end

  defp get_highlights(_tool) do
    # reward_string =
    #   CurrencyFormatter.format(
    #     tool.reward_value,
    #     tool.reward_currency,
    #     keep_decimals: true
    #   )

    # occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    # open_spot_count = tool.subject_count - occupied_spot_count
    # open_spot_string = "Nog #{open_spot_count} van #{tool.subject_count}"

    # available_title = dgettext("eyra-data-donation", "available.highlight.title")
    # reward_title = dgettext("eyra-data-donation", "reward.highlight.title")
    spots_title = dgettext("eyra-data-donation", "spots.highlight.title")

    # available_text = dgettext("eyra-data-donation", "available.future.highlight.text", from: "15 june", till: "22 june 2021")

    [ %{title: spots_title, text: ""}]
  end

end
