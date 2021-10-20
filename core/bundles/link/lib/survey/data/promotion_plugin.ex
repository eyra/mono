defmodule Link.Survey.PromotionPlugin do
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Crew
  }

  alias CoreWeb.Router.Helpers, as: Routes
  alias Core.Pools.Submissions
  alias Core.Promotions
  alias Core.Promotions.CallToAction
  alias Core.Promotions.CallToAction.Target
  alias Core.Survey.Tools

  alias CoreWeb.Promotion.Plugin

  @behaviour Plugin

  @impl Plugin
  def info(promotion_id, %{assigns: %{current_user: user}}) do
    promotion = Promotions.get!(promotion_id)
    submission = Submissions.get!(promotion)
    tool = Tools.get_by_promotion(promotion_id)

    call_to_action = get_call_to_action()
    byline = get_byline(tool)
    highlights = get_highlights(tool, submission)
    closed? = not open?(tool, user)

    languages =
      if tool.language != nil do
        [tool.language]
      else
        nil
      end

    %{
      closed?: closed?,
      call_to_action: call_to_action,
      highlights: highlights,
      devices: tool.devices,
      languages: languages,
      byline: byline
    }
  end

  @impl Plugin
  def get_cta_path(promotion_id, "apply", %{assigns: %{current_user: user}} = socket) do
    tool = Tools.get_by_promotion(promotion_id)
    campaign = Campaign.Context.get!(tool.study_id)
    crew = Campaign.Context.get_or_create_crew!(campaign)

    member =
      case Crew.Context.member?(crew, user) do
        true -> Crew.Context.get_member!(crew, user)
        false -> Crew.Context.apply_member!(crew, user)
      end

    _task = Crew.Context.get_or_create_task!(crew, member, :online_study)

    Routes.live_path(socket, Systems.Crew.TaskPage, :campaign, campaign.id)
  end

  defp get_call_to_action() do
    %CallToAction{
      label: dgettext("link-survey", "apply.cta.title"),
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

  defp get_highlights(
         %{
           subject_count: subject_count,
           duration: duration,
           study_id: study_id
         },
         %{
           reward_value: reward_value
         }
       ) do
    open_spot_count = Campaign.Context.count_open_spots(study_id)
    spots_title = dgettext("link-survey", "spots.highlight.title")

    spots_text =
      dgettext("link-survey", "spots.highlight.text", open: open_spot_count, total: subject_count)

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    reward_title = dgettext("link-survey", "reward.highlight.title")

    reward_value =
      case reward_value do
        nil -> "?"
        value -> value
      end

    reward_text = "#{reward_value} credits"

    [
      %{title: duration_title, text: duration_text},
      %{title: reward_title, text: reward_text},
      %{title: spots_title, text: spots_text}
    ]
  end

  defp open?(%{study_id: study_id}, user) do
    campaign = Campaign.Context.get!(study_id)
    crew = Campaign.Context.get_or_create_crew!(campaign)
    Campaign.Context.open?(study_id) || Crew.Context.member?(crew, user)
  end
end
