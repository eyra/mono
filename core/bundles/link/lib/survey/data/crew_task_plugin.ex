defmodule Link.Survey.CrewTaskPlugin do
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Crew
  }

  alias Core.Pools.Submissions
  alias Systems.Crew.TaskPlugin.CallToAction

  alias CoreWeb.Router.Helpers, as: Routes

  @behaviour Systems.Crew.TaskPlugin

  @impl Systems.Crew.TaskPlugin
  def info(task_id, %{assigns: %{current_user: user}} = _socket) do
    task = Crew.Context.get_task!(task_id)
    crew = Crew.Context.get!(task.crew_id)
    campaign = Campaign.Context.get!(crew.reference_id, [:survey_tool])
    tool = campaign.survey_tool
    promotion = Core.Promotions.get!(tool.promotion_id)
    submission = Submissions.get!(promotion)

    subtitle = make_subtitle(task)
    text = make_text(task, promotion)
    call_to_action = make_call_to_action(task, crew, user)
    highlights = get_highlights(task, submission)

    %{
      hero_title: dgettext("link-survey", "task.hero.title"),
      title: promotion.title,
      subtitle: subtitle,
      text: text,
      call_to_action: call_to_action,
      highlights: highlights
    }
  end

  defp make_subtitle(%{status: status}) do
    case status do
      :pending -> dgettext("link-survey", "task.pending.subtitle")
      :completed -> dgettext("link-survey", "task.completed.subtitle")
    end
  end

  defp make_text(%{status: status}, %{expectations: expectations}) do
    case status do
      :pending -> expectations
      :completed -> dgettext("link-survey", "task.completed.text")
    end
  end

  defp make_call_to_action(%{status: status}, crew, user) do
    get_call_to_action(crew, user, status)
  end

  @impl Systems.Crew.TaskPlugin
  def get_cta_path(_task_id, "marketplace", socket) do
    Routes.live_path(socket, Link.Marketplace)
  end

  @impl Systems.Crew.TaskPlugin
  def get_cta_path(task_id, "open", %{assigns: %{current_user: user}}) do
    task = Crew.Context.get_task!(task_id)
    crew = Crew.Context.get!(task.crew_id)
    campaign = Campaign.Context.get!(crew.reference_id, [:survey_tool])
    tool = campaign.survey_tool

    prepare(tool.survey_url, crew, user)
  end

  def prepare(url, crew, user) do
    pubic_id = Crew.Context.public_id(crew, user)
    url_components = URI.parse(url)

    query =
      url_components.query
      |> decode_query()
      |> Map.put(:panl_id, pubic_id)
      |> URI.encode_query(:rfc3986)

    url_components
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp get_call_to_action(_crew, _user, :completed) do
    %CallToAction{
      label: dgettext("eyra-link", "marketplace.button"),
      target: %CallToAction.Target{type: :event, value: "marketplace"}
    }
  end

  defp get_call_to_action(crew, user, _) do
    if Crew.Context.member?(crew, user) do
      %CallToAction{
        label: dgettext("link-survey", "open.cta.title"),
        target: %CallToAction.Target{type: :event, value: "open"}
      }
    else
      %CallToAction{
        label: dgettext("link-survey", "apply.cta.title"),
        target: %CallToAction.Target{type: :event, value: "apply"}
      }
    end
  end

  defp get_highlights(
         %{
           started_at: started_at,
           completed_at: completed_at
         },
         %{
           reward_value: reward_value
         }
       ) do
    started_title = dgettext("link-survey", "started.highlight.title")

    started_text =
      case started_at do
        nil ->
          dgettext("link-survey", "started.highlight.default")

        date ->
          date
          |> CoreWeb.UI.Timestamp.apply_timezone()
          |> CoreWeb.UI.Timestamp.humanize()
      end

    completed_title = dgettext("link-survey", "completed.highlight.title")

    completed_text =
      case completed_at do
        nil ->
          dgettext("link-survey", "completed.highlight.default")

        date ->
          date
          |> CoreWeb.UI.Timestamp.apply_timezone()
          |> CoreWeb.UI.Timestamp.humanize()
      end

    reward_title = dgettext("link-survey", "reward.highlight.title")

    reward_value =
      case reward_value do
        nil -> "?"
        value -> value
      end

    reward_text = "#{reward_value} credits"

    [
      %{title: reward_title, text: reward_text},
      %{title: started_title, text: started_text},
      %{title: completed_title, text: completed_text}
    ]
  end
end
