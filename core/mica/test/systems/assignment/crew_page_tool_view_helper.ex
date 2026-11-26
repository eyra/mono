defmodule Systems.Assignment.CrewPageToolViewHelper do
  @moduledoc """
  Compares a task on the crew page with its tool view on its own page. The test opens both
  with `Phoenix.LiveViewTest`, which needs its endpoint, and compares what they show: their
  text and the links in it.
  """

  alias Frameworks.Concept.LiveContext
  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Assignment
  alias Systems.Workflow

  @task_title "Tool task"

  def task_title, do: @task_title

  @doc """
  An online assignment without consent whose one task is the tool of `tool_ref`, with `user`
  as participant, so its crew page shows that tool.
  """
  def create_assignment(tool_ref, user) do
    auth_node = Factories.insert!(:auth_node)
    workflow = Assignment.Factories.create_workflow()
    Assignment.Factories.create_workflow_item(workflow, tool_ref, @task_title)
    info = Assignment.Factories.create_info("10", 100)

    assignment =
      Assignment.Factories.create_assignment(info, nil, workflow, auth_node, :online)

    Assignment.Public.add_participant!(assignment, user)
    assignment
  end

  @doc """
  The session of the tool view on its own: the tool with all its data, and the context the
  crew page gives its task. `data` adds what a tool view needs beyond that.
  """
  def tool_view_session(tool_ref, user, data \\ %{}) do
    tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down), force: true)

    context =
      %{
        current_user: user,
        timezone: "UTC",
        title: @task_title,
        icon: nil,
        tool_ref: tool_ref,
        presentation: :embedded,
        user_state: %{}
      }
      |> Map.merge(data)
      |> LiveContext.new()

    %{"live_context" => context}
  end

  @doc "What the task's tool view shows in the crew page's HTML."
  def crew_task_content(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("#tool_view")
    |> content()
  end

  @doc "What a tool view on its own shows in its HTML."
  def tool_view_content(html) do
    html
    |> Floki.parse_document!()
    |> content()
  end

  defp content(nodes) do
    %{
      text: nodes |> Floki.text(sep: " ") |> String.split() |> Enum.join(" "),
      links: nodes |> Floki.attribute("a", "href") |> Enum.sort()
    }
  end
end
