defmodule Frameworks.Signal.TestHelper do
  import ExUnit.Assertions

  defmacro assert_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      {_, {_, message}} = assert_receive({:signal_test, {^signal, _}}, 1000)
      message
    end
  end

  defmacro refute_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      refute_received({:signal_test, {^signal, _}}, 1000)
    end
  end

  def assert_signals_dispatched(signal, count) do
    for _ <- 1..count do
      assert_signal_dispatched(signal)
    end
  end

  def intercept({:force, :ok}, _message), do: :ok
  def intercept({:force, :error}, _message), do: {:error, :force_error}
  def intercept({:force, :continue}, _message), do: {:continue, :follow_up, "Hello, world!"}
  def intercept({:follow_up, {:force, :continue}}, %{follow_up: "Hello, world!"}), do: :ok

  def intercept(signal, message) do
    send(self(), {:signal_test, {signal, message}})
    {:error, :unhandled_signal}
  end
end
