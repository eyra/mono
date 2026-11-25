# `Mica.SaaS.Routes`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/saas/routes.ex#L1)

Splices the routes of a SaaS's systems into the SaaS's router:

    defmodule NextWeb.Router do
      use NextWeb, :router
      require Mica.SaaS.Routes

      Mica.SaaS.Routes.override_routes(Next.SaaS)
      Mica.SaaS.Routes.system_routes(Next.SaaS)
    end

Each system offers its routes as quoted blocks (`c:Mica.System.override_routes/0`,
`c:Mica.System.routes/0`); these macros splice them in `c:Mica.SaaS.systems/0`
order. The systems are read while the macro expands, so the router is compiled
against the SaaS it names, not against `config :mica, saas:`.

# `override_routes`
*macro* 

Splices `override_routes/0` of all systems of `saas`, and records their paths
for `MicaWeb.PathCheck` (a SaaS's own pages that shadow Mica's).

# `system_routes`
*macro* 

Splices `routes/0` of all systems of `saas`, in `systems/0` order.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
