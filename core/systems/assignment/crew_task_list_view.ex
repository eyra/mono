defmodule Systems.Assignment.CrewTaskListView do
  use CoreWeb, :live_component
  use Systems.Assignment.CrewWorkHelpers

  @impl true
  def update(
        %{
          work_items: work_items,
          crew: crew,
          user: user,
          timezone: timezone,
          panel_info: panel_info
        },
        socket
      ) do
    show_task_list? = Enum.count(work_items) > 1

    {
      :ok,
      socket
      |> assign(
        work_items: work_items,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        show_task_list?: show_task_list?
      )
      |> update_participant()
      |> update_selected_item()
      |> compose_child(:work_list_view)
      |> compose_child(:tool_ref_view)
    }
  end

  defp update_selected_item(%{assigns: %{selected_item: selected_item}} = socket)
       when not is_nil(selected_item) do
    socket
  end

  defp update_selected_item(%{assigns: %{work_items: [single_work_item]}} = socket) do
    socket |> assign(selected_item: single_work_item)
  end

  defp update_selected_item(socket) do
    socket |> assign(selected_item: nil)
  end

  # Behaviours

  @impl true
  def handle_tool_exited(socket) do
    socket
    |> hide_modal_tool_ref_view_if_needed()
    |> handle_task_completed()
  end

  @impl true
  def handle_tool_initialized(socket) do
    socket |> send_event(:tool_ref_view, "tool_initialized")
  end

  # Compose

  @impl true
  def compose(:work_list_view, %{work_items: work_items}) do
    work_list = %{
      items: Enum.map(work_items, &map_item/1),
      selected_item_id: nil
    }

    %{module: Workflow.WorkListView, params: %{work_list: work_list}}
  end

  def compose(
        :tool_ref_view,
        %{
          user: user,
          participant: participant,
          timezone: timezone,
          selected_item: {%{title: title, tool_ref: tool_ref} = selected_item, task}
        }
      ) do
    icon = get_icon(selected_item)

    %{
      module: Workflow.ToolRefView,
      params: %{
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        task: task,
        visible: true,
        user: user,
        participant: participant,
        timezone: timezone
      }
    }
  end

  def compose(:tool_ref_view, _) do
    nil
  end

  # Events

  @impl true
  def handle_event(
        "work_item_selected",
        %{"item" => item_id},
        %{assigns: %{work_items: work_items}} = socket
      ) do
    item_id = String.to_integer(item_id)
    selected_item = Enum.find(work_items, fn {%{id: id}, _} -> id == item_id end)

    launcher = launcher(selected_item)

    {
      :noreply,
      socket
      |> assign(selected_item: selected_item, launcher: launcher)
      |> compose_child(:tool_ref_view)
      |> show_modal_tool_ref_view_if_needed()
      |> start_task(selected_item)
    }
  end

  def handle_event("tool_initialized", payload, socket) do
    {:noreply, socket |> send_event(:tool_ref_view, "tool_initialized", payload)}
  end

  def handle_event("complete_task", _, socket) do
    {:noreply, socket |> handle_task_completed()}
  end

  # Private

  defp show_modal_tool_ref_view_if_needed(%{assigns: %{show_task_list?: true}} = socket) do
    socket |> show_modal(:tool_ref_view, :full)
  end

  defp show_modal_tool_ref_view_if_needed(socket) do
    socket
  end

  defp hide_modal_tool_ref_view_if_needed(%{assigns: %{show_task_list?: true}} = socket) do
    socket |> hide_modal(:tool_ref_view)
  end

  defp hide_modal_tool_ref_view_if_needed(socket) do
    socket
  end

  defp get_icon(%{group: group}) when is_binary(group) do
    String.downcase(group)
  end

  defp get_icon(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full">
        <%= if @show_task_list? do %>
            <.task_list>
                <.child name={:work_list_view} fabric={@fabric} />
            </.task_list>
        <% else %>
          <div class={"w-full h-full p-4 sm:p-8"}>
            <.child name={:tool_ref_view} fabric={@fabric} />
          </div>
        <% end %>
      </div>
    """
  end
end
