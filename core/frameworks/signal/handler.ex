defmodule Frameworks.Signal.Handler do
  @type signal :: atom | map | {:atom, signal}
  @type message :: any
  @callback intercept(signal, message) :: any()
  defmacro __using__(_opts) do
    quote do
      alias Frameworks.Signal

      @behaviour Signal.Handler
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
        {:ok, :ignored}
      end
    end
  end
end
