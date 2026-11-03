defmodule MicaWeb.Live.Feature.Viewport do
  @callback handle_resize(socket :: Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  defmacro __using__(_) do
    quote do
      @behaviour MicaWeb.Live.Feature.Viewport

      alias MicaWeb.UI.Responsive.Viewport
      alias MicaWeb.UI.Responsive.Breakpoint

      # stubs, handled by Live Hook
      def handle_event("viewport_changed", _, socket), do: {:noreply, socket}
      def handle_info(:viewport_updated, socket), do: {:noreply, socket}

      # optional feature
      def handle_resize(socket), do: socket
      defoverridable handle_resize: 1
    end
  end
end
