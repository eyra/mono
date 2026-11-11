# `Systems.Notify.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/_public.ex#L1)

Public API for `Systems.Notify`. Domain code calls `record_event/1` from
wherever a notifiable thing happens; the scheduler + channels take it from
there.

# `mark_seen`

Mark messages as seen by the user. Each channel adapter's `mark_seen/1`
callback (if implemented) runs the side effect (e.g. NA clears the NBA);
message status flips to `:seen` and `seen_at` stamped.

Filter options (at least one required):

    * `correlation_id: "participation:42"` — match a specific correlation
    * `event_types: [:contribution_accepted, :contribution_declined]` — match by type

Idempotent: messages already `:seen` are ignored.

# `record_event`

Record a domain event and hand it to the scheduler.

Also increments a `Systems.Monitor` counter for aggregate observability;
Monitor failures don't fail the event persistence.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
