defmodule Systems.Assignment.CrewPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts

  use Systems.Observatory.Public
  use CoreWeb.LiveRemoteIp
  use CoreWeb.Layouts.Stripped.Component, :projects

  require Logger

  alias CoreWeb.UI.Timestamp

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
        model: model
      )
      |> update_panel_info(session)
      |> observe_view_model()
      |> update_flow()
    }
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
    |> update_flow()
    |> update_menus()
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

  def store(
        %{assigns: %{panel_info: panel_info, model: assignment, remote_ip: remote_ip}} = socket,
        key,
        data
      ) do
    meta_data = %{
      remote_ip: remote_ip,
      timestamp: Timestamp.now() |> DateTime.to_unix(),
      key: key
    }

    assignment
    |> Storage.Private.storage_info()
    |> Storage.Public.store(panel_info, data, meta_data)

    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.stripped menus={@menus} footer?={false}>
        <.flow fabric={@fabric} />
      </.stripped>
    """
  end
end
