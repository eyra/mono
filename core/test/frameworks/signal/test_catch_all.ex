defmodule Frameworks.Signal.TestCatchAll do
  @moduledoc """
  Catches all unhandled signals and returns :ok to prevent test failures.
  Should be used sparingly and only when explicitly needed.
  """

  def intercept(_signal, _message) do
    # Catch everything and return :ok to prevent unhandled signal errors
    :ok
  end
end
