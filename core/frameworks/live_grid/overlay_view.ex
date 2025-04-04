defmodule LiveGrid.OverlayView do
  @moduledoc """
      A modal LiveView that forwards bubbled events to its parent (typically a CoreView).
      Includes a default `"close"` event handler that bubbles `:close_modal`.

      ## Example

      ```elixir
        defmodule MyAppWeb.MyOverlayView do
          use LiveGrid.OverlayView

          def render(assigns) do
            ~H\"""
            <div class="modal">
              <p>Modal content</p>
              <button phx-click="close" phx-target={@myself}>Close</button>
            </div>
            \"""
          end
        end
      ```
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveComponent
      import LiveGrid

      def handle_info({:bubble, event_name, payload}, socket) do
        socket = bubble_event(socket, event_name, payload)
        {:noreply, socket}
      end

      def handle_event("close", _params, socket) do
        socket = bubble_event(socket, :close_modal, %{})
        {:noreply, socket}
      end

      defoverridable handle_info: 2, handle_event: 3
    end
  end
end
