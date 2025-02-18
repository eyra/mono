defmodule LiveMesh.Events do
  @moduledoc """
  Provides a standardized event bubbling mechanism for all LiveMesh components.

  ## Key Features:
  - **Handles event propagation out-of-the-box** from `Fragment → Panel → Section → Page`.
  - **Can be included in any LiveView via `use LiveMesh.Events`**.
  - **Ensures unhandled events are forwarded up the UI hierarchy**.
  - **Prevents unnecessary message passing** by only forwarding unhandled events.
  """

  defmodule Hook do
    use Phoenix.LiveView
    use LiveMesh.Hook
    alias LiveMesh.Events, as: Self

    def on_mount(_live_view_module, _params, _session, socket) do
      {
        :cont,
        socket
        |> handle_bubbling()
      }
    end

    defp handle_bubbling(socket) do
      attach_hook(socket, :handle_bubbling, :handle_info, fn
        {:bubble_event, event, params}, socket ->
          {:cont, socket |> Self.bubble_event(event, params)}

        _, socket ->
          {:cont, socket}
      end)
    end
  end

  defmacro __using__(_opts) do
    quote do
      on_mount({LiveMesh.Events.Hook, __MODULE__})
    end
  end

  def bubble_event(socket, event, params \\ %{}) do
    send(socket.parent_pid, {:bubble_event, event, params})
    socket
  end
end
