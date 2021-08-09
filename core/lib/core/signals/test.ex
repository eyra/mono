defmodule Core.Signals.Test do
  import ExUnit.Assertions

  def assert_signal_dispatched(signal, message) do
    assert_received({:signal_test, {signal, message}})
  end

  def dispatch(signal, message) do
    send(self(), {:signal_test, {signal, message}})
  end
end
