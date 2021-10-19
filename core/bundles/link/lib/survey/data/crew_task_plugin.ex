defmodule Link.Survey.CrewTaskPlugin do
  import CoreWeb.Gettext

  alias Systems.Campaign
  alias Systems.Crew
  alias Systems.Crew.TaskPlugin.CallToAction

  alias Core.Survey.Tools

  @behaviour Systems.Crew.TaskPlugin

  @impl Systems.Crew.TaskPlugin
  def info(task_id, %{assigns: %{current_user: user}} = _socket) do
    task = Crew.Context.get_task!(task_id)
    campaign = Campaign.Context.get!(task.reference_id)
    crew = Campaign.Context.get_or_create_crew(campaign)
    call_to_action = get_call_to_action(crew, user)

    %{call_to_action: call_to_action}
  end

  @impl Systems.Crew.TaskPlugin
  def get_cta_path(task_id, "open", %{assigns: %{current_user: user}}) do
    task = Crew.Context.get_task!(task_id)
    campaign = Campaign.Context.get!(task.reference_id)
    tool = Tools.get_survey_tool!(campaign.survey_tool_id)
    crew = Campaign.Context.get_or_create_crew(campaign)

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

  defp get_call_to_action(crew, user) do
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
end
