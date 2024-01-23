defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts
  use CoreWeb.Layouts.Workspace.Component, :profile

  alias Core
  import CoreWeb.Layouts.Workspace.Component

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(changesets: %{})
      |> compose_child(:form)
      |> update_menus()
    }
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(_, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def compose(:form, %{current_user: user}) do
    %{
      module: CoreWeb.User.Forms.Profile,
      params: %{user: user}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace menus={@menus}>
      <.stack fabric={@fabric} />
    </.workspace>
    """
  end
end
