defmodule Systems.DataDonation.TaskBuilderView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.SidePanel

  alias Systems.{
    DataDonation
  }

  import DataDonation.TaskViews

  @impl true
  def update(%{action: "delete", task: task}, socket) do
    DataDonation.Public.delete(task)
    {:ok, socket |> update_tasks()}
  end

  @impl true
  def update(%{action: "up", task: %{position: position} = task}, socket) do
    {:ok, _} = DataDonation.Public.update_position(task, position - 1)
    {:ok, socket |> update_tasks()}
  end

  @impl true
  def update(%{action: "down", task: %{position: position} = task}, socket) do
    {:ok, _} = DataDonation.Public.update_position(task, position + 1)
    {:ok, socket |> update_tasks()}
  end

  @impl true
  def update(%{id: id, tool_id: tool_id, flow: flow, library: library}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool_id: tool_id,
        flow: flow,
        library: library
      )
      |> update_tool()
      |> update_tasks()
    }
  end

  defp update_tool(%{assigns: %{tool_id: tool_id}} = socket) do
    tool = DataDonation.Public.get_tool!(tool_id)
    socket |> assign(tool: tool)
  end

  defp update_tasks(%{assigns: %{tool_id: tool_id}} = socket) do
    tasks = DataDonation.Public.list_tasks(tool_id, DataDonation.TaskModel.preload_graph(:down))
    socket |> assign(tasks: tasks)
  end

  @impl true
  def handle_event("add", %{"item" => item}, %{assigns: %{tool: tool}} = socket) do
    {:ok, _} = DataDonation.Public.add_task(tool, "#{item}_task")

    {
      :noreply,
      socket
      |> update_tasks()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div id={:task_builder} class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @flow.title %></Text.title2>
            <Text.body><%= @flow.description %></Text.body>
            <.spacing value="M" />
            <.list tasks={@tasks} parent={%{type: __MODULE__, id: @id}} />
          </Area.content>
        </div>
        <div class="flex-shrink-0 w-side-panel">
          <.side_panel id={:library} parent={:task_builder}>
            <Margin.y id={:page_top} />
            <.library {@library} />
          </.side_panel>
        </div>
      </div>
    </div>
    """
  end
end
