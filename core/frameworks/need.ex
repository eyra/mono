defmodule Frameworks.Need do
  @moduledoc """
  Process-level dependency injection for runtime config.

  Resolves which implementation to use by checking the process dictionary
  first, falling back to Application env. Allows tests and E2E sessions
  to inject alternative implementations without affecting other processes.
  """

  def resolve(key) do
    Process.get({__MODULE__, key}) || Application.fetch_env!(:core, key)
  end

  def inject(key, value) do
    Process.put({__MODULE__, key}, value)
  end
end
