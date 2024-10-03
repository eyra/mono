defmodule CoreWeb.Live.Hook.Viewport do
  @moduledoc """
    Live Hook that injects the current viewport and breakpoint.
  """
  use Frameworks.Concept.LiveHook

  import CoreWeb.UI.Responsive.Breakpoint
  import CoreWeb.UI.Responsive.Viewport

  @impl true
  def on_mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      socket
      |> set_initial_viewport()
      |> assign_breakpoint()
      |> handle_viewport_changed(live_view_module)
    }
  end

  defp set_initial_viewport(socket) do
    case {connected?(socket), get_connect_params(socket)} do
      {true, %{"viewport" => viewport}} ->
        breakpoint = breakpoint(viewport)

        assign(socket,
          viewport: viewport,
          breakpoint: breakpoint
        )

      _ ->
        socket
    end
  end

  defp handle_viewport_changed(socket, live_view_module) do
    attach_hook(socket, :handle_viewport_changed, :handle_event, fn
      "viewport_changed", new_viewport, socket ->
        {:cont, socket |> update_viewport(live_view_module, new_viewport)}

      _, _, socket ->
        {:cont, socket}
    end)
  end

  defp update_viewport(socket, live_view_module, new_viewport) do
    old_viewport = Map.get(socket.assigns, :viewport, nil)

    if new_viewport != old_viewport do
      new_breakpoint = breakpoint(new_viewport)

      send(self(), :viewport_updated)

      socket
      |> assign(viewport: new_viewport)
      |> assign(breakpoint: new_breakpoint)
      |> optional_apply(live_view_module, :update_view_model)
      |> optional_apply(live_view_module, :handle_resize)
    else
      socket
    end
  end
end
