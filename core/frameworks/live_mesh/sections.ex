defmodule LiveMesh.Sections do
  @moduledoc """
  Enables support for multiple nested Sections inside a Page or another Section.
  """

  defmacro __using__(_opts) do
    quote do
      @doc """
      Registers a Section inside the current LiveView.
      """
      def add_section(socket, module, opts \\ []) do
        sections = [{module, opts} | get_sections(socket.assigns)]
        assign(socket, :sections, sections)
      end

      @doc """
      Removes a Section from the current LiveView.
      """
      def remove_section(socket, module) do
        sections = get_sections(socket.assigns)
        sections = List.delete(sections, {module, []})
        assign(socket, :sections, sections)
      end

      @doc """
      Retrieves all registered Sections inside the LiveView.
      """
      def get_sections(assigns) do
        Map.get(assigns, :sections, [])
      end
    end
  end
end
