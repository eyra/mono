# `Frameworks.Pixel.FabricBridge`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/pixel/fabric_bridge.ex#L1)

Temporary shim while Fabric is being retired.

Pixel live_components emit events to their parent LiveView. During the
Fabric-retirement window a parent may still be Fabric-based (`use MicaWeb,
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

# `emit_to_parent`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
