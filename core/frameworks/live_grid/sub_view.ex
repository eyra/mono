defmodule LiveGrid.SubView do
  @moduledoc """
    A nested LiveView that automatically forwards bubbled events to its parent unless intercepted.
    Uses the `:parent_pid` to forward the events.

    ## Example

    ```elixir
    defmodule MyAppWeb.MySubView do
      use LiveGrid.SubView

      def render(assigns) do
        ~H\"""
        <div>
          <button phx-click="trigger_navigate" phx-target={@myself}>Navigate</button>
          <button phx-click="trigger_modal" phx-target={@myself}>Open Modal</button>
        </div>
        \"""
      end

      def handle_event("trigger_navigate", _params, socket) do
        socket = bubble_event(socket, :navigate, %{"path" => "/new-page"})
        {:noreply, socket}
      end

      def handle_event("trigger_modal", _params, socket) do
        socket = bubble_event(socket, :open_modal, %{"id" => "some-modal"})
        {:noreply, socket}
      end
    end
    ```
    ## Intercept Example

    ```elixir
    def handle_info({:bubble, :navigate, payload}, socket) do
      socket = assign(socket, :last_path, payload["path"])
      {:noreply, intercept_event(socket)}
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

      defoverridable handle_info: 2
    end
  end

  def bubble_event(socket, event_name, payload) do
    send(socket.parent_pid, {:bubble, event_name, payload})
    socket
  end

  # marker for intercepting events
  def intercept_event(socket), do: socket
end
