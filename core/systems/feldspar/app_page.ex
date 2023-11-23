defmodule Systems.Feldspar.AppPage do
  alias Systems.Feldspar
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :projects

  require Logger

  import Feldspar.AppView

  @impl true
  def mount(%{"id" => app_id}, _session, socket) do
    app_url = Feldspar.Public.get_public_url(app_id) <> "/index.html"
    Logger.info("Starting feldspar app from: #{app_url}")

    {
      :ok,
      socket
      |> update_menus()
      |> assign(app_url: app_url, error: nil)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus} footer?={false}>
      <.app_view url={@app_url} />
    </.stripped>
    """
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
end
