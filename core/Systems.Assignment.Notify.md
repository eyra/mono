# `Systems.Assignment.Notify`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/_notify.ex#L1)

Notification events published by the Assignment system.

Add new events here as they're introduced elsewhere in the codebase; the
channel list drives which delivery adapters `Systems.Notify.Dispatcher`
fans out to.

# `notify_events`

Returns the list of `{event_type, opts}` declared in this module. Used
by `Systems.Notify.EventType` to build the global registry.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
