defmodule Systems.Manual.ToolView do
  use CoreWeb, :modal_live_view

  alias Systems.Workflow

  def dependencies(), do: [:title, :current_user, :tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("close", _payload, socket) do
    {:noreply, publish_event(socket, :close)}
  end

  @impl true
  def handle_event("done", _, socket) do
    {:noreply, publish_event(socket, :tool_completed)}
  end

  # Consume :done event from Manual.View and convert to :tool_completed
  @impl true
  def consume_event(%{name: :done}, socket) do
    {:stop, publish_event(socket, :tool_completed)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full min-h-0 flex flex-col">
      <.element {Map.from_struct(@vm.manual_view)} socket={@socket} />
    </div>
    """
  end
end
