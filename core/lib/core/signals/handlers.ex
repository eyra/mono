defmodule Core.Signals.Handlers do
  @callback dispatch(signal :: atom(), message :: any()) :: any()
  defmacro __using__(_opts) do
    quote do
      @behaviour Core.Signals.Handlers
      @before_compile Core.Signals.Handlers
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl true
      def dispatch(_signal, _message), do: :ok
    end
  end
end
