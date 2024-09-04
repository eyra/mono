defmodule CoreWeb.Live.Feature.Uri do
  @callback handle_uri(Socket.t()) :: Socket.t()

  defmacro __using__(_opts \\ nil) do
    quote do
      @behaviour CoreWeb.Live.Feature.Uri

      @impl true
      def handle_uri(socket), do: socket

      defoverridable handle_uri: 1
    end
  end
end
