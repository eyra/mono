defmodule Systems.Feldspar.AppPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts
  use CoreWeb.Layouts.Stripped.Component, :projects

  require Logger

  alias Systems.Feldspar

  @impl true
  def mount(%{"id" => app_id}, _session, socket) do
    app_url = Feldspar.Public.get_public_url(app_id) <> "/index.html"
    Logger.info("[Feldspar.AppPage] Starting feldspar app from: #{app_url}")

    {
      :ok,
      socket
      |> update_menus()
      |> assign(
        app_url: app_url,
        error: nil
      )
      |> compose_child(:app_view)
    }
  end

  @impl true
  def compose(:app_view, %{app_url: app_url}) do
    %{
      module: Feldspar.AppView,
      params: %{
        url: app_url,
        locale: Gettext.get_locale()
      }
    }
  end

  @impl true
  def handle_event("feldspar_event", %{"__type__" => type, "json_string" => event}, socket) do
    {
      :noreply,
      socket |> handle(type, event)
    }
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {
      :noreply,
      socket |> handle(nil, inspect(event))
    }
  end

  defp handle(socket, "CommandSystemDonate", event) do
    Frameworks.Pixel.Flash.put_error(socket, "Unsupported CommandSystemDonate " <> event)
    socket
  end

  defp handle(socket, "CommandSystemExit", event) do
    Frameworks.Pixel.Flash.put_error(socket, "Unsupported CommandSystemExit " <> event)
    socket
  end

  defp handle(socket, _, event) do
    Frameworks.Pixel.Flash.put_error(socket, "Unsupported " <> event)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus} footer?={false}>
      <.stack fabric={@fabric} />
    </.stripped>
    """
  end
end
