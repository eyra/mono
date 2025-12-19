defmodule Systems.Document.ToolView do
  use CoreWeb, :modal_live_view
  use Frameworks.Pixel

  import Frameworks.Pixel.Line

  alias Systems.Workflow

  def dependencies(), do: [:title, :tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, initialized: false)}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("tool_initialized", _payload, socket) do
    {:noreply, assign(socket, initialized: true)}
  end

  @impl true
  def handle_event("done", _payload, socket) do
    {:noreply, publish_event(socket, :tool_completed)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row w-full h-full justify-center">
      <div class="flex-grow" />
      <div class="w-full h-full max-w-[1200px] p-4 lg:p-8">
        <div class="w-full">
          <div class="flex flex-row items-center w-full gap-4" data-state="visible">
            <Text.title2 margin="">{@vm.title}</Text.title2>
            <div class="flex-grow" />
          </div>
          <.spacing value="M" />
          <.line />
          <div class="flex flex-col w-full h-full">
            <div>
              <.live_component {@vm.pdf_view} />
            </div>
            <.spacing value="M" />
            <div class="flex flex-row-reverse w-full pb-4 lg:pb-8">
              <div>
                <Button.dynamic {@vm.done_button} />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex-grow" />
    </div>
    """
  end
end
