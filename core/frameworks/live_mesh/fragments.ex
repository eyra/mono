defmodule LiveMesh.Fragments do
  @moduledoc """
  Enables support for multiple nested Fragments inside a Page or another Fragment.
  """

  defmacro __using__(_opts) do
    quote do
      @doc """
      Registers a Fragment inside the current LiveView.
      """
      def add_fragment(socket, module, opts \\ []) do
        fragments = [{module, opts} | get_fragments(socket.assigns)]
        assign(socket, :fragments, fragments)
      end

      @doc """
      Removes a Fragment from the current LiveView.
      """
      def remove_fragment(socket, module) do
        fragments = get_fragments(socket.assigns)
        fragments = List.delete(fragments, {module, []})
        assign(socket, :fragments, fragments)
      end

      @doc """
      Retrieves all registered Fragments inside the LiveView.
      """
      def get_fragments(assigns) do
        Map.get(assigns, :fragments, [])
      end
    end
  end
end
