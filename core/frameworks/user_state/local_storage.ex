defmodule Frameworks.UserState.LocalStorage do
  @moduledoc """
  LocalStorage backend for user state persistence.

  Uses Phoenix LiveView push_event to communicate with the browser's
  localStorage via the user_state.js JavaScript hook.
  """

  @behaviour Frameworks.UserState.Storage

  @impl true
  def save(socket, key, value) do
    Phoenix.LiveView.push_event(socket, "save_user_state", %{key: key, value: value})
  end
end
