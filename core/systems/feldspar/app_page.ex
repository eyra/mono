defmodule Systems.Feldspar.AppPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  require Logger

  alias Systems.Feldspar

  @impl true
  def mount(%{"id" => app_id}, _session, socket) do
    app_url = Feldspar.Public.get_public_url(app_id) <> "/index.html"
    Logger.info("[Feldspar.AppPage] Starting feldspar app from: #{app_url}")

    {
      :ok,
      socket
      |> assign(
        app_id: app_id,
        app_url: app_url,
        error: nil,
        active_menu_item: nil
      )
      |> compose_child(:app_view)
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def compose(:app_view, %{app_id: app_id, app_url: app_url}) do
    %{
      module: Feldspar.AppView,
      params: %{
        key: "app_#{app_id}",
        url: app_url,
        locale: CoreWeb.Live.Hook.Locale.get_locale()
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
