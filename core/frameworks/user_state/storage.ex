defmodule Frameworks.UserState.Storage do
  @moduledoc """
  Behaviour for user state storage backends.

  Defines the contract for storing and retrieving user state key/value pairs.
  """

  alias Phoenix.LiveView.Socket

  @doc """
  Saves a key/value pair to storage.

  Returns the socket with any necessary side effects applied (e.g., push_event).
  """
  @callback save(socket :: Socket.t(), key :: String.t(), value :: any()) ::
              Socket.t()

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
