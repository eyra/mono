defmodule Systems.Feldspar.ToolView do
  use CoreWeb, :modal_live_view
  use CoreWeb, :verified_routes
  use Frameworks.Pixel

  require Logger

  alias Frameworks.Pixel.Logo
  alias Systems.Workflow

  def dependencies(),
    do: [
      :title,
      :icon,
      :tool_ref,
      :assignment_id,
      :participant,
      :workflow_item_id,
      :recovery
    ]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{tool_ref: tool_ref}}) do
    Workflow.ToolRefModel.tool(tool_ref)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok,
     assign(socket,
       started: false,
       loading: false,
       initialized: false,
       unfinished_attempt?: false,
       recovery_checked: false,
       preparing: false,
       exited: false,
       attempt_id: nil
     )}
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
  def handle_event("feldspar_recovery_checked", %{"unfinished" => unfinished}, socket) do
    socket =
      if socket.assigns.started do
        socket
      else
        socket
        |> assign(recovery_checked: true, unfinished_attempt?: unfinished == true)
        |> update_view_model()
      end

    {:noreply, socket}
  end

  def handle_event("prepare_start", _, socket) do
    cond do
      socket.assigns.started or socket.assigns.preparing or
          not socket.assigns.recovery_checked ->
        {:noreply, socket}

      socket.assigns.vm.error ->
        {:noreply, Frameworks.Pixel.Flash.put_error(socket, socket.assigns.vm.error)}

      true ->
        {:noreply,
         socket
         |> assign(preparing: true)
         |> update_view_model()
         |> push_event("feldspar:prepare", %{id: socket.assigns.vm.recovery_id})}
    end
  end

  def handle_event(
        "start",
        %{"attempt_id" => attempt_id},
        %{assigns: %{preparing: true}} = socket
      ) do
    socket =
      case parse_attempt_id(attempt_id) do
        {:ok, attempt_id} -> start_attempt(socket, attempt_id)
        _ -> cancel_preparation(socket)
      end

    {:noreply, update_view_model(socket)}
  end

  def handle_event("start", _, socket), do: {:noreply, socket}

  def handle_event("tool_initialized", _, socket) do
    socket =
      socket
      |> assign(initialized: true, loading: false)
      |> update_view_model()

    {:noreply, socket}
  end

  @impl true
  def handle_event("feldspar_event", _, %{assigns: %{started: false}} = socket),
    do: {:noreply, socket}

  def handle_event("feldspar_event", _, %{assigns: %{exited: true}} = socket),
    do: {:noreply, socket}

  def handle_event("feldspar_event", event, socket) do
    {:noreply, handle_feldspar_event(socket, event)}
  end

  defp parse_attempt_id(attempt_id) do
    Ecto.UUID.cast(attempt_id)
  end

  defp start_attempt(socket, attempt_id) do
    assign(socket,
      started: true,
      loading: true,
      initialized: false,
      unfinished_attempt?: false,
      preparing: false,
      exited: false,
      attempt_id: attempt_id
    )
  end

  defp cancel_preparation(socket) do
    assign(socket, preparing: false)
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
      socket |> assign(exited: true) |> publish_event(:tool_completed)
    else
      Frameworks.Pixel.Flash.put_info(
        socket,
        "Application stopped unexpectedly [#{code}]: #{info}"
      )
    end
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

  defp modal_id(%{live_nest: %{modal: %{element: %{id: id}}}}), do: id
  defp modal_id(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
      <div
        id={@vm.recovery_id}
        phx-hook="FeldsparRecovery"
        data-recovery-scope={@vm.recovery_scope}
        data-recovery-on-entry={@vm.recovery_on_entry}
        data-modal-id={modal_id(assigns)}
        class="w-full h-full"
        data-testid="feldspar-tool-view"
      >
        <%= if @started and @vm.app_view do %>
          <div
            data-testid="app-container"
            class={"w-full h-full pt-2 sm:pt-4 #{if @started and @initialized, do: "block", else: "hidden"}"}
          >
            <.element {Map.from_struct(@vm.app_view)} socket={@socket} />
          </div>
        <% end %>
        <div
          data-testid="start-container"
          class={"w-full h-full flex-col items-center justify-center py-8 #{if @started and @initialized, do: "hidden", else: "flex"}"}
        >
          <Area.sheet>
            <div class="flex flex-col gap-8 items-center px-8">
              <div>
                <%= if @vm.icon do %>
                  <Logo.platform platform={@vm.icon} variant={:square} class="w-24 h-24" />
                <% end %>
              </div>
              <%= if @vm.recovery do %>
                <Text.title2 align="text-center" margin=""><%= @vm.recovery.title %></Text.title2>
                <div data-testid="feldspar-recovery">
                  <Text.body align="text-center"><%= Phoenix.HTML.raw(@vm.recovery.description) %></Text.body>
                </div>
              <% else %>
                <Text.title2 align="text-center" margin=""><%= @vm.title %></Text.title2>
                <Text.body align="text-center"><%= @vm.description %></Text.body>
              <% end %>
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
