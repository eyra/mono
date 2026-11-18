# `MicaWeb.Web`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/web.ex#L1)

The blocks of a web module: controllers, views, components, channels and so on.

Mica and every SaaS have their own web module, built with this one:

    defmodule NextWeb do
      use MicaWeb.Web, router: MicaWeb.Router, endpoint: MicaWeb.Endpoint
    end

Code then uses its owner's web module, `use NextWeb, :routed_live_view` or
`use NextWeb, {:controller, formats: [:json]}`, and its `~p` is verified against
that `router:`. The blocks are the same for every web module; only the paths
differ. Mica's web module, `use MicaWeb.Web` without a router, builds its paths
with `~m` (`MicaWeb.Path`), which each SaaS checks against its own router.

Do NOT define functions inside the quoted expressions below. Instead, define any
helper function in modules and import those modules here.

# `channel`

# `controller`

# `embedded_live_view`

# `html`

# `live_component`

# `live_component_fabric`

# `live_features`

# `live_view_fabric`

# `mica_paths`

# `modal_live_view`

# `pixel`

# `routed_live_view`

# `router`

# `ui`

# `utility`

# `verified_routes`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
