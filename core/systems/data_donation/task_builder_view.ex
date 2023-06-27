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
  def update(%{action: "up", task: %{tool_id: tool_id, position: position} = task}, socket) do
    if task_above = DataDonation.Public.get_task(tool_id, position - 1) do
      DataDonation.Public.switch_position(task, task_above)
      {:ok, socket |> update_tasks()}
    else
      {:ok, socket}
    end
  end

  @impl true
  def update(%{action: "down", task: %{tool_id: tool_id, position: position} = task}, socket) do
    if task_below = DataDonation.Public.get_task(tool_id, position + 1) do
      DataDonation.Public.switch_position(task, task_below)
      {:ok, socket |> update_tasks()}
    else
      {:ok, socket}
    end
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
