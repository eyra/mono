defmodule LiveMesh.Modals do
  @moduledoc """
  Enables support for multiple nested Modals inside a Page or another Modal.
  """

  defmacro __using__(_opts) do
    quote do
      @doc """
      Registers a Modal inside the current LiveView.
      """
      def add_modal(socket, module, opts \\ []) do
        modals = [{module, opts} | get_modals(socket.assigns)]
        assign(socket, :modals, modals)
      end

      @doc """
      Removes a Modal from the current LiveView.
      """
      def remove_modal(socket, module) do
        modals = get_modals(socket.assigns)
        modals = List.delete(modals, {module, []})
        assign(socket, :modals, modals)
      end

      @doc """
      Retrieves all registered Modals inside the LiveView.
      """
      def get_modals(assigns) do
        Map.get(assigns, :modals, [])
      end
    end
  end
end
