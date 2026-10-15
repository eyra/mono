defmodule Frameworks.UserState.LiveHook do
  @moduledoc """
  LiveView hook that loads user state from localStorage on mount.

  This hook is used by routed LiveViews to load the initial user state
  from the browser's localStorage via connect params.

  ## Usage

  Add to your routed LiveView:

      on_mount({Frameworks.UserState.LiveHook, __MODULE__})

  The hook will:
  1. Check if user_state is already assigned (skip if so)
  2. Load user_state from connect params (sent by JavaScript)
  3. Parse the flat localStorage format into nested structure
  4. Assign to socket.assigns.user_state
  """

  use Frameworks.Concept.LiveHook

  alias Frameworks.UserState

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    # Skip if user_state already assigned (from LiveContext)
    # or if this is a nested LiveView (get_connect_params will fail)
    if Map.has_key?(socket.assigns, :user_state) do
      {:cont, socket}
    else
      try do
        user_state = load_user_state(socket)
        {:cont, assign(socket, user_state: user_state)}
      rescue
        RuntimeError ->
          # Nested LiveView - skip user_state assignment
          # It will be provided by Context hook
          {:cont, socket}
      end
    end
  end

  defp load_user_state(socket) do
    case {connected?(socket), get_connect_params(socket)} do
      {true, %{"user_state" => flat_state}} when is_map(flat_state) ->
        user_id = get_user_id(socket)
        UserState.parse_user_state(flat_state, user_id)

      _ ->
        %{}
    end
  end

  defp get_user_id(%{assigns: %{current_user: %{id: id}}}), do: id
  defp get_user_id(_), do: nil
end
