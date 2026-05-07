defmodule Frameworks.UserState.Storage do
  @moduledoc """
  Behaviour for user state storage backends.

  Defines the contract for storing and retrieving user state key/value pairs.
  """

  @doc """
  Saves a key/value pair to storage.

  Returns the socket with any necessary side effects applied (e.g., push_event).
  """
  @callback save(socket :: Phoenix.LiveView.Socket.t(), key :: String.t(), value :: any()) ::
              Phoenix.LiveView.Socket.t()

  @doc """
  Returns the configured storage backend module.
  """
  def backend do
    Application.get_env(:core, :user_state_storage, Frameworks.UserState.LocalStorage)
  end

  @doc """
  Saves a key/value pair using the configured storage backend.
  """
  def save(socket, key, value) do
    backend().save(socket, key, value)
  end
end
