# `Mica.Systems`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/systems.ex#L1)

Mica's own systems (`Mica.System`), the start of every `c:Mica.SaaS.systems/0`.

Not in `Mica`: about 290 modules `use Mica`, and they recompile whenever a
module that `Mica` names changes, or anything that module names. System
modules name their signal handlers, notifiers and channels, and through them
most of the app.

# `all`

Routes are spliced in this order. Keep it a literal list.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
