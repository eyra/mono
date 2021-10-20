defmodule CoreWeb.DataDonation.PromotionPlugin do
  import CoreWeb.Gettext

  alias Systems.Campaign
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
      closed?: false,
      call_to_action: call_to_action,
      highlights: highlights,
      devices: [:desktop],
      languages: [],
      byline: byline
    }
  end

  @impl Plugin
  def get_cta_path(promotion_id, "apply", %{assigns: %{current_user: user}} = socket) do
    tool = Tools.get_by_promotion(promotion_id)
    Tools.apply_participant(tool, user)
    Tools.get_or_create_task(tool, user)

    Routes.live_path(socket, CoreWeb.DataDonation.Uploader, tool.id)
  end

  @impl Plugin
  def get_cta_path(promotion_id, "open", socket) do
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
      Campaign.Context.get!(tool.study_id)
      |> Campaign.Context.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("eyra-data-donation", "by.author.label")}: " <> authors
  end

  defp get_highlights(%{
         study_id: study_id,
         subject_count: subject_count,
         reward_value: reward_value,
         reward_currency: reward_currency
       }) do
    open_spot_count = Campaign.Context.count_open_spots(study_id)

    spots_title = dgettext("eyra-data-donation", "spots.highlight.title")
    spots_text = "Nog #{open_spot_count} van #{subject_count}"

    available_title = dgettext("eyra-data-donation", "available.highlight.title")

    available_text =
      dgettext("eyra-data-donation", "available.future.highlight.text",
        from: "15 june",
        till: "15 augustus 2021"
      )

    reward_title = dgettext("eyra-data-donation", "reward.highlight.title")

    reward_text = CurrencyFormatter.format(reward_value, reward_currency, keep_decimals: true)

    [
      %{title: available_title, text: available_text},
      %{title: spots_title, text: spots_text},
      %{title: reward_title, text: reward_text}
    ]
  end
end
