defmodule Frameworks.Signal.LiveFeature do
  @moduledoc """
  Swallows the `{:signal_test, _}` message that `Frameworks.Signal.TestRecorder`
  sends back to the dispatching process during tests with `isolate_signals/1`.

  Without this stub, any LiveView that dispatches a signal from its own process
  would crash with `no function clause matching` in the test environment.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      def handle_info({:signal_test, _}, socket), do: {:noreply, socket}
    end
  end
end
