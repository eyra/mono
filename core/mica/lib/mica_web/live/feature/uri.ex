defmodule MicaWeb.Live.Feature.Uri do
  @callback handle_uri(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  defmacro __using__(_opts \\ nil) do
    quote do
      @behaviour MicaWeb.Live.Feature.Uri

      @impl true
      def handle_uri(socket), do: socket

      defoverridable handle_uri: 1
    end
  end
end
