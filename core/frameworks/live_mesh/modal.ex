defmodule LiveMesh.Modal do
  @moduledoc """
  A `Modal` is a stateful LiveView used to display overlay. Modal state is managed by a parent LiveView.

  ## Key Rules:
  - **Supports 'Sections' by default**.
  - **Supports event bubbling** for centralized modal state management.
  - **Provides helper function to hide the modal**
  """

  use Phoenix.LiveView

  defmodule Hook do
    use LiveMesh.Hook

    def on_mount(_live_view_module, _params, _session, socket) do
      {
        :cont,
        socket
        |> assign(modal_open: false)
        |> handle_modal_state()
      }
    end

    defp handle_modal_state(socket) do
      attach_hook(socket, :handle_modal_state, :handle_info, fn
        :modal_opened, socket ->
          {:cont, assign(socket, modal_open: true)}

        :modal_hidden, socket ->
          {:cont, assign(socket, modal_open: false)}

        _, socket ->
          {:cont, socket}
      end)
    end
  end

  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      use LiveMesh.Sections
      use LiveMesh.Events

      alias LiveMesh.Modal

      on_mount({LiveMesh.Modal.Hook, __MODULE__})

      @impl true
      def hide_modal(socket) do
        # Lifecycle is managed by the parent LiveView
        send(socket.parent_pid, {:bubble_event, "hide_modal"})
        {:noreply, socket}
      end
    end
  end
end
