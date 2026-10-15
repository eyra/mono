defmodule Frameworks.Signal.TestRecorder do
  @moduledoc """
  Records signals for test assertions and handles them.
  Returns :ok to prevent infinite loops.
  """

  def intercept(signal, message) do
    send(self(), {:signal_test, {signal, message}})
    # Don't continue - that would create a new signal and cause infinite loop
    # Just return :ok to indicate the signal was handled
    :ok
  end
end
