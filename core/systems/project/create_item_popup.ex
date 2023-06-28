defmodule Systems.Project.CreateItemPopup do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector

  alias Systems.{
    Project
  }

  # Handle Tool Type Selector Update
  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: :tool_selector},
        %{assigns: %{tool_labels: tool_labels}} = socket
      ) do
    %{id: selected_tool} = Enum.find(tool_labels, &(&1.id == active_item_id))

    {
      :ok,
      socket
      |> assign(selected_tool: selected_tool)
    }
  end

  # Initial Update
  @impl true
  def update(%{id: id, node: node, target: target}, socket) do
    title = dgettext("eyra-project", "create.item.title")

    {
      :ok,
      socket
      |> assign(id: id, node: node, target: target, title: title)
      |> init_tools()
      |> init_buttons()
    }
  end

  defp init_tools(socket) do
    selected_tool = :empty
    tool_labels = Project.Tools.labels(selected_tool)
    socket |> assign(tool_labels: tool_labels, selected_tool: selected_tool)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :send, event: "proceed", target: myself},
          face: %{
            type: :primary,
            label: dgettext("eyra-project", "create.proceed.button")
          }
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event(
        "proceed",
        _,
        %{assigns: %{selected_tool: selected_tool}} = socket
      ) do
    create_item(socket, selected_tool)

    {:noreply, socket |> close()}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> close()}
  end

  defp close(%{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: :close})
    socket
  end

  defp create_item(%{assigns: %{node: node}}, tool) do
    name = Project.Tools.translate(tool)
    Project.Assembly.create_item(name, node, tool)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= @title %></Text.title3>
      <.spacing value="S" />
      <.live_component
        module={Selector}
        id={:tool_selector}
        items={@tool_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <.spacing value="M" />
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </div>
    """
  end
end
