defmodule Systems.Instruction.ToolView do
  use MicaWeb, :modal_live_view
  use Frameworks.Pixel

  alias Systems.Instruction
  alias Systems.Workflow

  def dependencies(), do: [:tool_ref]

  # The host gives the tool without its pages
  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    %{id: tool_id} = Workflow.ToolRefModel.tool(tool_ref)
    Instruction.Public.get_tool!(tool_id, Instruction.ToolModel.preload_graph(:pages))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, publish_event(socket, :tool_completed)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @vm.page_view do %>
          <.live_component {@vm.page_view} />
        <% end %>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic {@vm.done_button} />
        </.wrap>
      </Area.content>
    </div>
    """
  end
end
