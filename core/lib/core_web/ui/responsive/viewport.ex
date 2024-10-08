defmodule CoreWeb.UI.Responsive.Viewport do
  import Phoenix.Component, only: [assign: 2]
  import CoreWeb.UI.Responsive.Breakpoint, only: [breakpoint: 1]

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
