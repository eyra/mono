defmodule LiveMesh.Panels do
  @moduledoc """
  Enables support for multiple nested Panels inside a Page or another Panel.
  """

  defmacro __using__(_opts) do
    quote do
      @doc """
      Registers a Panel inside the current LiveView.
      """
      def add_panel(socket, module, opts \\ []) do
        panels = [{module, opts} | get_panels(socket.assigns)]
        assign(socket, :panels, panels)
      end

      @doc """
      Removes a Panel from the current LiveView.
      """
      def remove_panel(socket, module) do
        panels = get_panels(socket.assigns)
        panels = List.delete(panels, {module, []})
        assign(socket, :panels, panels)
      end

      @doc """
      Retrieves all registered Panels inside the LiveView.
      """
      def get_panels(assigns) do
        Map.get(assigns, :panels, [])
      end
    end
  end
end
