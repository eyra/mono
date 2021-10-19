defmodule Link.Lab.PromotionPlugin do
  import CoreWeb.Gettext

  alias Systems.Campaign
  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.Lab.Tools

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
      # devices: tool.devices,
      devices: [],
      languages: [],
      byline: byline
    }
  end

  @impl Plugin
  def get_cta_path(promotion_id, "apply", socket) do
    tool = Tools.get_by_promotion(promotion_id)
    CoreWeb.Router.Helpers.live_path(socket, CoreWeb.Lab.Public, tool.id)
  end

  defp get_call_to_action(_tool, _user) do
    %CallToAction{
      label: dgettext("link-lab", "apply.cta.title"),
      target: %Target{type: :event, value: "apply"}
    }
  end

  defp get_byline(tool) do
    authors =
      Campaign.Context.get!(tool.study_id)
      |> Campaign.Context.list_authors()
      |> Enum.map(& &1.fullname)
      |> Enum.join(", ")

    "#{dgettext("link-survey", "by.author.label")}: " <> authors
  end

  defp get_highlights(_tool) do
    []
  end
end
