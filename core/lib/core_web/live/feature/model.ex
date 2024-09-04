defmodule CoreWeb.Live.Feature.Model do
  @callback get_model(map(), map(), Socket.t()) :: map | struct | nil

  defmacro __using__(_opts \\ nil) do
    quote do
      @behaviour CoreWeb.Live.Feature.Model

      @impl true
      def get_model(_params, _session, _socket), do: nil

      defoverridable get_model: 3
    end
  end
end
