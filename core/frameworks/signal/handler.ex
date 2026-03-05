defmodule Frameworks.Signal.Handler do
  @moduledoc false
  @type signal :: atom | map | {:atom, signal}
  @type message :: any
  @type result :: :ok | {:error, atom()} | {:continue, atom(), any()}

  @callback intercept(signal, message) :: result()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Signal.Handler

      alias Frameworks.Signal

      @before_compile Signal.Handler

      defp dispatch!(signal, message) do
        Signal.Public.dispatch!(signal, message)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      require Logger

      @impl true
      def intercept(signal, _message) do
        {:error, :unhandled_signal}
      end
    end
  end
end
