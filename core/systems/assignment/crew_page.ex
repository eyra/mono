defmodule Systems.Assignment.CrewPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts

  use Systems.Observatory.Public
  use CoreWeb.LiveRemoteIp
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.Layouts.Stripped.Component, :projects

  require Logger

  alias CoreWeb.UI.Timestamp
  alias Core.ImageHelpers
  alias Frameworks.Pixel.Hero
  alias Frameworks.Pixel.ModalView

  alias Systems.{
    Assignment,
    Storage
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    %{crew: crew} = Assignment.Public.get!(String.to_integer(id), [:crew])
    crew
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    model = Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))

    {
      :ok,
      socket
      |> assign(
        id: id,
        model: model,
        image_info: nil,
        modal: nil
      )
      |> update_panel_info(session)
      |> observe_view_model()
      |> update_flow()
    }
  end

  def handle_view_model_updated(socket) do
    socket
    |> update_flow()
    |> update_image_info()
    |> update_menus()
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_image_info()
    |> update_menus()
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

  defp update_panel_info(socket, _) do
    assign(socket, panel_info: nil)
  end

  defp update_flow(%{assigns: %{vm: %{flow: flow}}} = socket) do
    socket |> install_children(flow)
  end

  def handle_info({:complete_task, _}, socket) do
    {:noreply, socket |> send_event(:flow, "complete_task")}
  end

  def handle_info(%{panel: :centerdata, request: request}, socket) do
    form =
      prepare_child(socket, :centerdata_form, Systems.Storage.Centerdata.Form, %{request: request})

    {:noreply, socket |> show_child(form)}
  end

  @impl true
  def handle_event("continue", _payload, socket) do
    {:noreply, socket |> show_next()}
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {
      :noreply,
      socket |> send_event(:flow, "feldspar_event", event)
    }
  end

  @impl true
  def handle_event("store", %{key: key, data: data}, socket) do
    {:noreply, socket |> store(key, data)}
  end

  @impl true
  def handle_event("show_modal", modal, socket) do
    {:noreply, socket |> assign(modal: modal)}
  end

  @impl true
  def handle_event("hide_modal", _, socket) do
    {:noreply, socket |> assign(modal: nil)}
  end

  def store(
        %{assigns: %{panel_info: panel_info, model: assignment, remote_ip: remote_ip}} = socket,
        key,
        data
      ) do
    meta_data = %{
      remote_ip: remote_ip,
      timestamp: Timestamp.now() |> DateTime.to_unix(),
      key: key,
      pid: self() |> :erlang.pid_to_list()
    }

    if storage_info = Storage.Private.storage_info(assignment) do
      Storage.Public.store(storage_info, panel_info, data, meta_data)
      socket
    else
      message = "Please setup connection to a data storage"
      Logger.error(message)
      socket |> put_flash(:error, message)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped menus={@menus} footer?={false}>
        <:header>
          <div class="h-[180px] bg-grey5">
          <%= if @image_info do %>
            <Hero.image title={@vm.info.title} subtitle={@vm.info.subtitle} logo_url={@vm.info.logo_url} image_info={@image_info} />
          <% end %>
          </div>
        </:header>

        <ModalView.dynamic modal={@modal} />

        <div id={:crew_page} class="w-full h-full flex flex-col" phx-hook="ViewportResize">
          <.flow fabric={@fabric} />
        </div>
      </.stripped>
    """
  end
end
