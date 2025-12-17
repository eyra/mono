defmodule Systems.Alliance.ToolView do
  use CoreWeb, :modal_live_view
  use Frameworks.Pixel

  alias Systems.Workflow

  def dependencies(), do: [:title, :description, :url, :tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("start_tool", _params, %{assigns: %{vm: %{url: url}}} = socket) do
    socket =
      socket
      |> publish_event({:close_modal, %{modal_id: "tool_modal"}})
      |> push_event("open_url", %{url: url})

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <Align.horizontal_center>
        <Area.sheet>
          <div class="flex flex-col gap-8 items-center px-8">
            <Text.title2 align="text-center" margin=""><%= @vm.title %></Text.title2>
            <Text.body align="text-center"><%= @vm.description %></Text.body>
            <.wrap>
              <Button.dynamic {@vm.button} />
            </.wrap>
          </div>
        </Area.sheet>
      </Align.horizontal_center>
    </div>
    """
  end
end
