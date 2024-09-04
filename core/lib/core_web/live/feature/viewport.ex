defmodule CoreWeb.Live.Feature.Viewport do
  @callback handle_resize(socket :: Socket.t()) :: Socket.t()

  defmacro __using__(_) do
    quote do
      @behaviour CoreWeb.Live.Feature.Viewport

      alias CoreWeb.UI.Responsive.Viewport
      alias CoreWeb.UI.Responsive.Breakpoint

      # stubs, handled by Live Hook
      def handle_event("viewport_changed", _, socket), do: {:noreply, socket}
      def handle_info(:viewport_updated, socket), do: {:noreply, socket}

      # optional feature
      def handle_resize(socket), do: socket
      defoverridable handle_resize: 1
    end
  end
end
