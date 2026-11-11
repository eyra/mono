# `Systems.Notify.EventType`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/event_type.ex#L1)

Global registry of notification event types → channel routing.

Built at first-use from the notifiers of the SaaS's systems
(`Mica.SaaS.notifiers/0`), unless `config :mica, Systems.Notify, notifiers: [...]`
overrides them; each notifier declares its events via
`use Systems.Notify.EventDeclaration`.

Cached in `:persistent_term` — one lookup at first call, direct-map after.

# `all`

# `channels_for`

# `known?`

# `reset`

Force a rebuild — useful in tests that swap notifier config on the fly.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
