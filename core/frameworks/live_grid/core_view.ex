defmodule LiveGrid.CoreView do
  @moduledoc """
    A root LiveView that handles bubbled events for navigation and modal control.

    Mounts with a `:modal_open?` assign set to `false`. Handles `:navigate`, `:open_modal`,
    and `:close_modal` events by default.

    ## Example
  ​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​
    ```elixir
    defmodule MyAppWeb.MyCoreView do
      use LiveGrid.CoreView
      alias MyAppWeb.MySubView
      def render(assigns) do
        ~H\"""
        <div>
          <.live_component module={MySubView} id="subview-1" parent_pid={self()} />
          <%= if @modal_open? do %>
            <div id="modal-1" class="modal-container">
              <.live_component module={MyAppWeb.MyOverlayView} id="modal-1-overlay" parent_pid={self()} />
            </div>
          <% end %>
        </div>
        \"""
      end
    end
    ```
  """

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      import LiveGrid

      def mount(_params, _session, socket) do
        socket = assign(socket, :modal_open?, false)
        {:ok, socket}
      end

      def handle_info({:bubble, :navigate, %{"path" => path}}, socket) do
        {:noreply, push_patch(socket, to: path)}
      end

      def handle_info({:bubble, :open_modal, _payload}, socket) do
        {:noreply, assign(socket, :modal_open?, true)}
      end

      def handle_info({:bubble, :close_modal, _payload}, socket) do
        {:noreply, assign(socket, :modal_open?, false)}
      end

      defoverridable mount: 3, handle_info: 2
    end
  end
end
