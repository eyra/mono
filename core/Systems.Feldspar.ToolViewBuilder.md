# `Systems.Feldspar.ToolViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/feldspar/tool_view_builder.ex#L1)

# `view_model`

Builds view model for Feldspar tool view.

## Parameters
- tool: The Feldspar tool model
- assigns: Contains presentation data, an opaque recovery context and an optional
  start screen description from the host. With `autostart: true` in the live context
  the host has shown its own start screen, and the app starts without this one,
  unless a previous attempt didn't finish: then this start screen shows its notice.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
