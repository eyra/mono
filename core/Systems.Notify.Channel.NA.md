# `Systems.Notify.Channel.NA`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/channel/na.ex#L1)

Next-Action channel adapter. Creates an NBA on the recipient's Home for the
event, via the existing `Systems.NextAction` infrastructure.

Payload shape: `%{"action_module" => module_string, "key" => string,
"params" => map}`. Rendering of the NBA card copy still happens in
`<action_module>.to_view_model/2` at request time — that keeps locale-live
and lets the NBA update if the underlying data changes.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
