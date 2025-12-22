defmodule Systems.Feldspar.ToolView do
  use CoreWeb, :modal_live_view
  use CoreWeb, :verified_routes
  use Frameworks.Pixel

  alias Systems.Workflow

  def dependencies(), do: [:title, :icon, :tool_ref]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, started: false, loading: false, initialized: false)}
  end

  @impl true
  def handle_view_model_updated(%{assigns: %{vm: %{error: error}}} = socket)
      when not is_nil(error) do
    socket |> Frameworks.Pixel.Flash.put_error(error)
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("start", _, %{assigns: %{initialized: true}} = socket) do
    {:noreply, assign(socket, started: true)}
  end

  def handle_event("start", _, %{assigns: %{vm: %{error: error}}} = socket)
      when not is_nil(error) do
    {:noreply, socket |> Frameworks.Pixel.Flash.push_error(error)}
  end

  def handle_event("start", _, socket) do
    socket =
      socket
      |> assign(started: true, loading: true, initialized: false)
      |> update_view_model()

    {:noreply, socket}
  end

  def handle_event("tool_initialized", _, socket) do
    socket =
      socket
      |> assign(initialized: true, loading: false)
      |> update_view_model()

    {:noreply, socket}
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {:noreply, handle_feldspar_event(socket, event)}
  end

  defp handle_feldspar_event(
         socket,
         %{
           "__type__" => "CommandSystemExit",
           "code" => code,
           "info" => info
         }
       ) do
    if code == 0 do
      socket |> publish_event(:tool_completed)
    else
      Frameworks.Pixel.Flash.put_info(
        socket,
        "Application stopped unexpectedly [#{code}]: #{info}"
      )
    end
  end

  defp handle_feldspar_event(
         socket,
         %{
           "__type__" => "CommandSystemDonate",
           "key" => key,
           "json_string" => json_string
         }
       ) do
    socket
    |> publish_event({:donate, %{key: key, data: json_string}})
    |> Frameworks.Pixel.Flash.put_info("Donated")
  end

  defp handle_feldspar_event(socket, %{
         "__type__" => "CommandSystemEvent",
         "name" => "initialized"
       }) do
    socket
    |> assign(initialized: true, loading: false)
    |> update_view_model()
    |> publish_event(:tool_initialized)
  end

  defp handle_feldspar_event(socket, %{"__type__" => type}) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event " <> type)
  end

  defp handle_feldspar_event(socket, _) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event")
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full" data-testid="feldspar-tool-view">
        <%= if @vm.app_view do %>
          <div
            data-testid="app-container"
            class={"w-full h-full pt-2 sm:pt-4 #{if @started and @initialized, do: "block", else: "hidden"}"}
          >
            <.element {Map.from_struct(@vm.app_view)} socket={@socket} />
          </div>
        <% end %>
        <div
          data-testid="start-container"
          class={"absolute inset-0 items-center justify-center #{if @started and @initialized, do: "hidden", else: "flex"}"}
        >
          <Area.sheet>
            <div class="flex flex-col gap-8 items-center px-8">
              <div>
                <%= if @vm.icon do %>
                  <img class="w-24 h-24" src={~p"/images/icons/#{"#{@vm.icon}_square.svg"}"} onerror="this.src='/images/icons/placeholder_square.svg';" alt={@vm.icon}>
                <% end %>
              </div>
              <Text.title2 align="text-center" margin=""><%= @vm.title %></Text.title2>
              <Text.body align="text-center"><%= @vm.description %></Text.body>
              <.wrap>
                <Button.dynamic {@vm.button} />
              </.wrap>
            </div>
          </Area.sheet>
        </div>
      </div>
    """
  end
end
