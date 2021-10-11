defmodule Frameworks.Signal.Handler do
  @callback dispatch(signal :: atom(), message :: any()) :: any()
  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Signal.Handler
      @before_compile Frameworks.Signal.Handler
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl true
      def dispatch(_signal, _message), do: :ok
    end
  end
end
