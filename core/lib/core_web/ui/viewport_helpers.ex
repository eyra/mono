defmodule Coreweb.UI.ViewportHelpers do
  import Phoenix.LiveView

  @sm 640
  @md 768
  @lg 1024
  @xl 1280

  defmacro __using__(_) do
    quote do
      import Coreweb.UI.ViewportHelpers

      data(viewport, :map)
      data(breakpoint, :map)

      def handle_event("viewport_resize", viewport, socket) do
        {
          :noreply,
          socket
          |> assign(viewport: viewport)
          |> assign(breakpoint: Coreweb.UI.ViewportHelpers.current_breakpoint(viewport))
        }
      end
    end
  end

  def current_breakpoint(viewport) do
    width = viewport["width"]

    if width < @sm do
      :mobile
    else
      if width in @sm..@md do
        :sm
      else
        if width in @md..@lg do
          :md
        else
          if width in @lg..@xl do
            :lg
          else
            :xl
          end
        end
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
    breakpoint = current_breakpoint(viewport)
    assign(socket, breakpoint: breakpoint)
  end

  def assign_breakpoint(socket) do
    assign(socket, breakpoint: :mobile)
  end
end
