defmodule CoreWeb.Live.Hook.Timezone do
  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(_live_view_module, _params, _session, socket) do
    timezone =
      case {connected?(socket), get_connect_params(socket)} do
        {true, %{"timezone" => timezone}} -> timezone
        _ -> "Europe/Amsterdam"
      end

    {:cont, assign(socket, timezone: timezone)}
  end
end
