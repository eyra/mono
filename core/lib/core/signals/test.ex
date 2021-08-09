defmodule Core.Signals.Test do
  import ExUnit.Assertions

  defmacro assert_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      {_, {_, message}} = assert_received({:signal_test, {^signal, _}})
      message
    end
  end

  defmacro refute_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      refute_received({:signal_test, {^signal, _}})
    end
  end

  def assert_signals_dispatched(signal, count) do
    for _ <- 1..count do
      assert_signal_dispatched(signal)
    end
  end

  def dispatch(signal, message) do
    send(self(), {:signal_test, {signal, message}})
  end
end
