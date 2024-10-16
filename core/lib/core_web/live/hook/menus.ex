defmodule CoreWeb.Live.Hook.Menus do
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> update_menu_config(live_view_module)
      |> ensure_active_menu_item()
      |> update_menus(live_view_module)
      |> handle_uri(live_view_module)
      |> handle_view_model_updated(live_view_module)
      |> handle_viewport_updated(live_view_module)
    }
  end

  defp update_menu_config(socket, live_view_module) do
    menus_config = live_view_module.get_menus_config()
    assign(socket, menus_config: menus_config)
  end

  def update_menus(socket, live_view_module) do
    live_view_module.update_menus(socket)
  end

  defp handle_uri(socket, live_view_module) do
    attach_hook(socket, :menus_handle_uri, :handle_params, fn _params, _uri, socket ->
      {:cont, socket |> update_menus(live_view_module)}
    end)
  end

  defp handle_view_model_updated(socket, live_view_module) do
    attach_hook(socket, :menus_handle_view_model_updated, :handle_info, fn
      :view_model_updated, socket ->
        {:cont, socket |> update_menus(live_view_module)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp handle_viewport_updated(socket, live_view_module) do
    attach_hook(socket, :menus_viewport_updated, :handle_info, fn
      :viewport_updated, socket ->
        {:cont, socket |> update_menus(live_view_module)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp ensure_active_menu_item(
         %{assigns: %{menus_config: {menu_builder, menus, active_menu_item}}} = socket
       ) do
    socket |> assign(menus_config: {menu_builder, menus}, active_menu_item: active_menu_item)
  end

  defp ensure_active_menu_item(%{assigns: %{vm: %{active_menu_item: active_menu_item}}} = socket) do
    socket |> assign(active_menu_item: active_menu_item)
  end

  defp ensure_active_menu_item(%{assigns: %{active_menu_item: _}} = socket) do
    socket
  end

  defp ensure_active_menu_item(socket) do
    socket |> assign(active_menu_item: nil)
  end
end
