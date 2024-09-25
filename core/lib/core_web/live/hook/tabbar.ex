defmodule CoreWeb.Live.Hook.Tabbar do
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> update_tabbar_size(live_view_module)
      |> handle_viewport_updated(live_view_module)
    }
  end

  defp handle_viewport_updated(socket, live_view_module) do
    attach_hook(socket, :tabbar_viewport_updated, :handle_info, fn
      :viewport_updated, socket ->
        {:cont, socket |> update_tabbar_size(live_view_module)}

      _, socket ->
        {:cont, socket}
    end)
  end

  defp update_tabbar_size(socket, live_view_module) do
    optional_apply(socket, live_view_module, :update_tabbar_size)
  end
end
