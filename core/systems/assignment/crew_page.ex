defmodule Systems.Assignment.CrewPage do
  use CoreWeb, :routed_live_view
  use CoreWeb.Layouts.Stripped.Composer

  import LiveNest.HTML

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Viewport, __MODULE__})

  require Logger

  alias Core.ImageHelpers
  alias Frameworks.Pixel.Hero

  alias Systems.Assignment
  alias Systems.Project
  alias Systems.Storage

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    %{crew: crew} = Assignment.Public.get!(String.to_integer(id), [:crew])
    crew
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        image_info: nil,
        modal_toolbar_buttons: []
      )
      |> update_panel_info(session)
      |> update_image_info()
    }
  end

  @impl true
  def handle_view_model_updated(%{assigns: %{vm: %{session_id: session_id}}} = socket) do
    socket
    |> assign(session_id: session_id)
    |> update_image_info()
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_image_info()
  end

  defp update_image_info(
         %{assigns: %{viewport: %{"width" => viewport_width}, vm: %{info: %{image_id: image_id}}}} =
           socket
       ) do
    image_width = viewport_width
    image_height = 360
    image_info = ImageHelpers.get_image_info(image_id, image_width, image_height)

    socket
    |> assign(image_info: image_info)
  end

  defp update_image_info(socket) do
    socket
  end

  defp update_panel_info(socket, %{"panel_info" => panel_info}) do
    assign(socket, panel_info: panel_info)
  end

  defp update_panel_info(socket, _session) do
    assign(socket, panel_info: nil)
  end

  @impl true
  def handle_event("store", %{task: task, key: key, group: group, data: data}, socket) do
    {:noreply, socket |> store(task_identifier(socket, task, group, key), data)}
  end

  @impl true
  def handle_event("close_modal", %{"item" => modal_id}, socket) do
    {:noreply, socket |> handle_close_modal(modal_id)}
  end

  @impl true
  def consume_event(%{name: :onboarding_continue}, socket) do
    {:stop, socket |> handle_action(:onboarding_continue)}
  end

  @impl true
  def consume_event(
        %{name: :accept},
        %{assigns: %{model: model, current_user: user}} = socket
      ) do
    Assignment.Public.accept_member(model, user)
    socket = store(socket, onboarding_identifier(socket), "{\"status\":\"consent accepted\"}")
    {:stop, socket |> handle_action(:accept)}
  end

  @impl true
  def consume_event(
        %{name: :decline},
        %{assigns: %{model: model, current_user: user}} = socket
      ) do
    Assignment.Public.decline_member(model, user)
    socket = store(socket, onboarding_identifier(socket), "{\"status\":\"consent declined\"}")
    {:stop, socket |> handle_action(:decline)}
  end

  @impl true
  def consume_event(%{name: :retry}, socket) do
    {:stop, socket |> handle_action(:retry)}
  end

  @impl true
  def consume_event(%{name: :task_completed}, socket) do
    {:stop, socket}
  end

  @impl true
  def consume_event(%{name: :work_done}, socket) do
    {:stop, socket |> handle_action(:work_done)}
  end

  @impl true
  def consume_event(
        %{name: :store, payload: %{task: task, key: key, group: group, data: data}},
        socket
      ) do
    {:stop, store(socket, task_identifier(socket, task, group, key), data)}
  end

  # HTTP upload complete - blob stored via HTTP endpoint, schedule delivery
  @impl true
  def consume_event(
        %{
          name: :deliver_blob,
          payload: %{task: task, key: key, group: group, blob_id: blob_id}
        },
        socket
      ) do
    Logger.info(
      "[CrewPage] Blob stored, scheduling delivery: task=#{task} key=#{key} group=#{group} blob_id=#{blob_id}"
    )

    {:stop, deliver_blob(socket, task_identifier(socket, task, group, key), blob_id)}
  end

  defp handle_action(socket, action) do
    socket
    |> assign(action: action)
    |> update_view_model()
  end

  defp onboarding_identifier(%{
         assigns: %{model: assignment, panel_info: panel_info, session_id: session_id}
       }) do
    [
      [:assignment, assignment.id],
      [:participant, Map.get(panel_info, :participant, "")],
      [:key, "#{session_id}-onboarding"]
    ]
  end

  defp task_identifier(%{assigns: %{model: assignment, panel_info: panel_info}}, task, group, key) do
    [
      [:assignment, assignment.id],
      [:participant, Map.get(panel_info, :participant, "")],
      [:task, task],
      [:source, group],
      [:key, key]
    ]
  end

  defp store(socket, identifier, data) do
    %{assigns: %{panel_info: panel_info, model: assignment, remote_ip: remote_ip}} = socket

    meta_data = %{
      remote_ip: remote_ip,
      panel_info: panel_info,
      identifier: identifier
    }

    result =
      with {:ok, storage_endpoint} <- Project.Public.get_storage_endpoint_by(assignment),
           storage_info <- Storage.Private.storage_info(storage_endpoint) do
        Storage.Public.store(storage_endpoint, storage_info, data, meta_data)
      end

    case result do
      {:ok, _} ->
        socket

      {:error, step, reason, _} ->
        Logger.error("[CrewPage.store] FAILED at #{step}: #{inspect(reason)}")
        socket |> put_flash(:error, dgettext("eyra-assignment", "storage.failed.warning"))

      _ ->
        message = dgettext("eyra-assignment", "storage.not_available.warning")
        Logger.error("[CrewPage.store] #{message}")
        socket |> put_flash(:error, message)
    end
  end

  defp deliver_blob(socket, identifier, blob_id) do
    %{assigns: %{panel_info: panel_info, model: assignment, remote_ip: remote_ip}} = socket

    meta_data = %{
      remote_ip: remote_ip,
      panel_info: panel_info,
      identifier: identifier
    }

    result =
      with {:ok, storage_endpoint} <- Project.Public.get_storage_endpoint_by(assignment),
           storage_info <- Storage.Private.storage_info(storage_endpoint) do
        Storage.Public.deliver_blob(storage_endpoint, storage_info, blob_id, meta_data)
      end

    case result do
      {:ok, _} ->
        socket

      {:error, step, reason, _} ->
        Logger.error("[CrewPage.deliver_blob] FAILED at #{step}: #{inspect(reason)}")
        socket |> put_flash(:error, dgettext("eyra-assignment", "storage.failed.warning"))

      _ ->
        message = dgettext("eyra-assignment", "storage.not_available.warning")
        Logger.error("[CrewPage.deliver_blob] #{message}")
        socket |> put_flash(:error, message)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped menus={@menus} footer?={false} privacy_text={@vm.footer.privacy_text} terms_text={@vm.footer.terms_text}>
        <:header>
          <div class="h-[120px] sm:h-[180px] bg-grey5">
          <%= if @image_info do %>
            <Hero.image_banner title={@vm.info.title} subtitle={@vm.info.subtitle} logo_url={@vm.info.logo_url} image_info={@image_info} />
          <% end %>
          </div>
        </:header>

        <ModalView.dynamic modal={@modal} toolbar_buttons={@modal_toolbar_buttons} socket={@socket} />

        <div id={:crew_page} class="w-full h-full flex flex-col" phx-hook="Viewport">
          <%= if @vm.view do %>
            <div class="flex-1 min-h-0">
              <.element socket={@socket} {Map.from_struct(@vm.view)} />
            </div>
          <% end %>
        </div>
      </.stripped>
    """
  end
end
