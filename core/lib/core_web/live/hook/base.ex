defmodule CoreWeb.Live.Hook.Base do
  @moduledoc false
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(live_view_module, _params, _session, socket) do
    {
      :cont,
      assign(socket, live_view_module: live_view_module, popup: nil, dialog: nil, modal: nil)
    }
  end
end
