defmodule Frameworks.Signal.TestForceSwitch do
  @moduledoc """
  Handles test-specific {:force, *} signals for testing signal behavior.
  """

  def intercept({:force, :ok}, _message), do: :ok
  def intercept({:force, :error}, _message), do: {:error, :force_error}
  def intercept({:force, :continue}, _message), do: {:continue, :follow_up, "Hello, world!"}
  def intercept({:follow_up, {:force, :continue}}, %{follow_up: "Hello, world!"}), do: :ok

  # Not a force signal - continue to next handler
  def intercept(signal, message), do: {:continue, signal, message}
end
