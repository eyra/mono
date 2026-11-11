# `Systems.Notify.EventDeclaration`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/event_declaration.ex#L1)

Per-system notification event registration, mirroring the `_routes.ex`
convention. A system opts in by dropping a `_notify.ex`:

    defmodule Systems.Assignment.Notify do
      use Systems.Notify.EventDeclaration

      event(:contribution_accepted, channels: [:email, :na])
      event(:contribution_declined, channels: [:email, :na])
    end

Then list the notifier module in the system's `_system.ex` so
`Systems.Notify.EventType` finds it:

    def notifiers, do: [Systems.Assignment.Notify]

Only systems that actually publish events need a `_notify.ex`.

# `event`
*macro* 

---

*Consult [api-reference.md](api-reference.md) for complete listing*
