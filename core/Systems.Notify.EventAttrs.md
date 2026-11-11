# `Systems.Notify.EventAttrs`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/notify/event_attrs.ex#L1)

Input struct for `Systems.Notify.Public.record_event/1`. Keeps the
contract explicit so callers get a `FunctionClauseError` on the wrong
shape instead of a silent `nil` deep in normalize.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
