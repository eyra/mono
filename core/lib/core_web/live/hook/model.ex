defmodule CoreWeb.Live.Hook.Model do
  @moduledoc "A Live Hook that injects the LiveView data model"
  use Frameworks.Concept.LiveHook

  @impl true
  def mount(live_view_module, params, session, socket) do
    model =
      Frameworks.Utility.Module.optional_apply(live_view_module, :get_model, [
        params,
        session,
        socket
      ])

    {:cont, socket |> assign(model: model)}
  end
end
