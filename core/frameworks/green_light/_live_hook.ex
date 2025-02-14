defmodule Frameworks.GreenLight.LiveHook do
  @moduledoc """
    Live Hook that enables automatic authorization checks.
  """
  use Frameworks.Concept.LiveHook
  use Core, :auth
  use CoreWeb, :verified_routes
  require Logger

  @impl true
  def on_mount(live_view_module, params, session, socket) do
    if access_allowed?(live_view_module, params, session, socket) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/access_denied")}
    end
  end

  defp access_allowed?(live_view_module, params, session, socket) do
    user = Map.get(socket.assigns, :current_user)

    if function_exported?(live_view_module, :get_authorization_context, 3) do
      can_access? =
        auth_module().can_access?(
          user,
          live_view_module.get_authorization_context(params, session, socket)
          |> print_auth_roles(),
          live_view_module
        )

      user && Logger.notice("User #{user.id} can_access? #{live_view_module}: #{can_access?}")
      can_access?
    else
      auth_module().can_access?(user, live_view_module)
    end
  end
end
