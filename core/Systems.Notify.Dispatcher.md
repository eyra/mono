# `Systems.Notify.Dispatcher`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/dispatcher.ex#L1)

Event → Messages → Channel delivery.

For an event, looks up the channels routed to it, asks each channel's
adapter to build its payload, persists a `MessageModel` per channel, then
hands each message to its channel for delivery. Delivery result flips the
message status to `:sent` / `:failed`.

Channels that decide the event isn't relevant to them can return `:skip`
from `build_payload/1` — no message is persisted for that channel.

# `dispatch`

Fan an event out to all channels registered for its type. Persists a message
per channel and delivers immediately (v1 has no batching / scheduling).
Returns `{:ok, messages}` or `{:error, reason}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
