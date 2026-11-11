# `Systems.Notify.Channel.Email`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/channel/email.ex#L1)

Email channel adapter. Builds a Bamboo email per event and ships it via the
existing `Systems.Email` pipeline.

Payload shape: `%{"factory_fn" => atom_string, "args" => [...]}`. Rendering
happens at delivery time in the recipient's locale — we persist only the raw
args so a resend still respects locale/copy changes.

Register per-event-type payload builders as `build_payload/1` clauses below.
Unhandled types return `:skip` so the dispatcher just doesn't create an
email message for them.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
