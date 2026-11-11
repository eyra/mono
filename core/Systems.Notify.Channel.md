# `Systems.Notify.Channel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/channel.ex#L1)

Channel-adapter behaviour. A channel takes a persisted `MessageModel` (with
its event context) and ships it. The dispatcher handles status transitions
based on the return value — adapters just focus on delivery.

A channel MUST also expose `build_payload/1` — turning an event into the
channel-specific payload the dispatcher persists on the message. This
keeps rendering (subject/body/action-params) next to delivery.

# `build_payload`

```elixir
@callback build_payload(%Systems.Notify.EventModel{
  __meta__: term(),
  actor_user: term(),
  actor_user_id: term(),
  correlation_id: term(),
  dispatched_at: term(),
  id: term(),
  inserted_at: term(),
  messages: term(),
  metadata: term(),
  source: term(),
  subject_user: term(),
  subject_user_id: term(),
  type: term(),
  updated_at: term()
}) :: {:ok, map()} | {:error, term()} | :skip
```

# `deliver`

```elixir
@callback deliver(%Systems.Notify.MessageModel{
  __meta__: term(),
  attempts: term(),
  channel: term(),
  delivered_at: term(),
  event: term(),
  event_id: term(),
  failure_reason: term(),
  id: term(),
  inserted_at: term(),
  payload: term(),
  seen_at: term(),
  status: term(),
  updated_at: term()
}) :: :ok | {:error, term()}
```

# `mark_seen`
*optional* 

```elixir
@callback mark_seen(%Systems.Notify.MessageModel{
  __meta__: term(),
  attempts: term(),
  channel: term(),
  delivered_at: term(),
  event: term(),
  event_id: term(),
  failure_reason: term(),
  id: term(),
  inserted_at: term(),
  payload: term(),
  seen_at: term(),
  status: term(),
  updated_at: term()
}) :: :ok | {:error, term()}
```

Called when `Systems.Notify.Public.mark_seen/2` matches this message.
Adapters translate "user has seen the outcome" into channel-specific side
effects (NA clears the NBA, future InApp marks the inbox record as read,
Email is a no-op). Optional — dispatch handles absence as a no-op.

# `adapter`

The channel module for a channel name, from `Mica.SaaS.notify_channels/0`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
