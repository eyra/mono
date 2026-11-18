# `MicaWeb`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web.ex#L1)

Mica's web module: the entrypoint for defining Mica's web interface, such as
controllers, views, channels and so on.

    use MicaWeb, {:controller, [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}
    use MicaWeb, :html

The blocks are defined in `MicaWeb.Web`. Mica has no router of its own, so its
code builds paths with `~m` (`MicaWeb.Path`), which every SaaS checks against
its router. Code of a SaaS uses its own web module (`NextWeb`, `MicaSaasWeb`),
so its `~p` is verified against that SaaS's router.

# `__using__`
*macro* 

When used, dispatch to the appropriate controller/view/etc applying given opts.

# `channel`

# `controller`

# `embedded_live_view`

# `html`

# `live_component`

# `live_component_fabric`

# `live_features`

# `live_view_fabric`

# `modal_live_view`

# `pixel`

# `routed_live_view`

# `router`

# `static_paths`

# `ui`

# `utility`

# `verified_routes`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
