defmodule CoreWeb.DataDonation.PromotionPlugin do
  import CoreWeb.Gettext

  alias Core.Studies
  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.DataDonation.Tools

  alias CoreWeb.Router.Helpers, as: Routes
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
      devices: [:desktop],
      byline: byline
    }
  end

  @impl Plugin
  def handle_event(promotion_id, "apply", %{assigns: %{current_user: user}} = socket) do
    tool = Tools.get_by_promotion(promotion_id)
    Tools.apply_participant(tool, user)
    Tools.get_or_create_task(tool, user)

    Routes.live_path(socket, CoreWeb.DataDonation.Uploader, tool.id)
  end

  @impl Plugin
  def handle_event(promotion_id, "open", socket) do
    tool = Tools.get_by_promotion(promotion_id)
    Routes.live_path(socket, CoreWeb.DataDonation.Uploader, tool.id)
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

  defp get_byline(tool) do
    authors =
      Studies.get_study!(tool.study_id)
      |> Studies.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("eyra-data-donation", "by.author.label")}: " <> authors
  end

  defp get_highlights(tool) do
    occupied_spot_count = Tools.count_tasks(tool, [:pending, :completed])
    open_spot_count = tool.subject_count - occupied_spot_count

    spots_title = dgettext("eyra-data-donation", "spots.highlight.title")
    spots_text = "Nog #{open_spot_count} van #{tool.subject_count}"

    available_title = dgettext("eyra-data-donation", "available.highlight.title")

    available_text =
      dgettext("eyra-data-donation", "available.future.highlight.text",
        from: "15 june",
        till: "15 augustus 2021"
      )

    reward_title = dgettext("eyra-data-donation", "reward.highlight.title")

    reward_text =
      CurrencyFormatter.format(tool.reward_value, tool.reward_currency, keep_decimals: true)

    [
      %{title: available_title, text: available_text},
      %{title: spots_title, text: spots_text},
      %{title: reward_title, text: reward_text}
    ]
  end
end
