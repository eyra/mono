# `Systems.Notify.Scheduler`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/scheduler.ex#L1)

Decides when + how an event turns into messages.

v1 is trivial: schedule = dispatch now. The abstraction is here so that later
work (batching windows, quiet-hours, throttling, user preferences) plugs in
as rule modules without touching event producers.

# `schedule`

Schedule an event for delivery. In v1 dispatches immediately; future
revisions will consult rules (event type, recipient state, time) to decide
channels + timing + batching.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
