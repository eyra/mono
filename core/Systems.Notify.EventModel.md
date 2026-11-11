# `Systems.Notify.EventModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/event_model.ex#L1)

A raw fact that something happened. Records the "what + who + when" —
channels + timing are decided later by `Systems.Notify.Scheduler`.

`metadata` holds event-type-specific raw data (IDs + snapshotted fields).
Rendering to user-facing text happens at message-build time in the
recipient's locale.

# `changeset`

# `preload_graph`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
