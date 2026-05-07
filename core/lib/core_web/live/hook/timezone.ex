defmodule CoreWeb.Live.Hook.Timezone do
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    # Skip if timezone already assigned (from LiveContext)
    # or if this is a nested LiveView (get_connect_params will fail)
    if Map.has_key?(socket.assigns, :timezone) do
      {:cont, socket}
    else
      try do
        # Deprecated: Only for root LiveViews without timezone in context
        timezone =
          case {connected?(socket), get_connect_params(socket)} do
            {true, %{"timezone" => timezone}} -> timezone
            _ -> "Europe/Amsterdam"
          end

        {:cont, assign(socket, timezone: timezone)}
      rescue
        RuntimeError ->
          # Nested LiveView - skip timezone assignment
          # It will be provided by Context hook
          {:cont, socket}
      end
    end
  end
end
