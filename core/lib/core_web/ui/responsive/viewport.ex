defmodule CoreWeb.UI.Responsive.Viewport do
  import Phoenix.Component
  import CoreWeb.UI.Responsive.Breakpoint

  @callback handle_resize(socket :: Socket.t()) :: Socket.t()

  defmacro __using__(_) do
    quote do
      @behaviour CoreWeb.UI.Responsive.Viewport

      import CoreWeb.UI.Responsive.Viewport
      import CoreWeb.UI.Responsive.Breakpoint

      def handle_event("viewport_resize", new_viewport, socket) do
        new_breakpoint = breakpoint(new_viewport)

        {
          :noreply,
          socket
          |> assign(viewport: new_viewport)
          |> assign(breakpoint: new_breakpoint)
          |> handle_resize()
        }
      end
    end
  end

  def assign_viewport(%{private: %{connect_params: %{"viewport" => viewport}}} = socket) do
    assign(socket, viewport: viewport)
  end

  def assign_viewport(socket) do
    assign(socket, viewport: %{"width" => 0, "height" => 0})
  end

  def assign_breakpoint(%{private: %{connect_params: %{"viewport" => viewport}}} = socket) do
    assign(socket, breakpoint: breakpoint(viewport))
  end

  def assign_breakpoint(socket) do
    assign(socket, breakpoint: {:unknown, 0})
  end
end
