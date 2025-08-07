defmodule CoreWeb.Live.Hook.User do
  @moduledoc """
    Live Hook that injects the current user.
  """
  use Frameworks.Concept.LiveHook
  alias Systems.Account

  @impl true
  def mount(_live_view_module, _params, session, socket) do
    {:cont, socket |> assign(current_user: current_user(session))}
  end

  defp current_user(%{assigns: %{current_user: current_user}}), do: current_user

  defp current_user(%{"user_token" => user_token}) do
    Account.Public.get_user_by_session_token(user_token)
  end

  defp current_user(%{"user" => user}) do
    user
  end

  defp current_user(_), do: nil
end
