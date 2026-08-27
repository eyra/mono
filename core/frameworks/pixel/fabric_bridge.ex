defmodule Frameworks.Pixel.FabricBridge do
  @moduledoc """
  Temporary shim while Fabric is being retired.

  Pixel live_components emit events to their parent LiveView. During the
  Fabric-retirement window a parent may still be Fabric-based (`use CoreWeb,
  :live_view_fabric`, populates a `:fabric` assign on any child it renders
  via compose_child) or already migrated to pure LiveNest (no `:fabric`
  assign). This helper picks the right transport at runtime so a Pixel
  component doesn't need to know its host's framework.

  - Fabric parent: route via `Fabric.send_event(:parent, ...)`, unchanged.
  - Non-Fabric parent: `LiveNest.Event.Publisher.publish_event(socket, {name, payload})`
    delivers `%LiveNest.Event{}` to the parent, which catches it via
    `LiveNest.Event.Consumer.consume_event/2`.

  Any Pixel live_component that emits parent-bound events should
  `use Frameworks.Pixel.FabricBridge`. That imports `emit_to_parent/2` and
  injects a fabric-capture `update/2` clause so the parent's `:fabric` assign
  is preserved on the child socket (which is how Fabric.LiveComponent used
  to make this work implicitly).

  Delete this module once no Fabric parents remain — every remaining `use`
  will surface as a compile error pointing at a caller that still needs its
  Fabric branch removed.
  """

  import LiveNest.Event.Publisher, only: [publish_event: 2]

  def emit_to_parent(socket, {name, payload}) do
    if Map.has_key?(socket.assigns, :fabric) do
      Fabric.send_event(socket, :parent, name, payload)
    else
      publish_event(socket, {atomize(name), payload})
    end
  end

  defp atomize(name) when is_atom(name), do: name
  defp atomize(name) when is_binary(name), do: String.to_atom(name)

  defmacro __using__(_opts) do
    quote do
      import Frameworks.Pixel.FabricBridge, only: [emit_to_parent: 2]

      # Capture the :fabric assign when a Fabric parent renders this
      # component via compose_child, so emit_to_parent/2 can route parent
      # events correctly. Mirrors what Fabric.LiveComponent's __using__ used
      # to do implicitly — including assigning :id, which several Pixel
      # renders reference as `@id`. Removed together with the surrounding
      # module once no Fabric parents remain.
      @impl true
      def update(%{id: id, fabric: fabric} = params, socket) do
        params = Map.delete(params, :fabric)

        socket =
          socket
          |> Phoenix.Component.assign(:id, id)
          |> Phoenix.Component.assign(:fabric, fabric)

        update(params, socket)
      end
    end
  end
end
