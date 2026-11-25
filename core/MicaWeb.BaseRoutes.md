# `MicaWeb.BaseRoutes`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/base_routes.ex#L1)

Mica's routes that belong to no system, for a SaaS router. The router puts
them in its own order, around the systems' routes (`Mica.SaaS.Routes`):

    MicaWeb.Pipelines.define()
    Mica.SaaS.Routes.override_routes(Next.SaaS)
    MicaWeb.BaseRoutes.auth_routes()
    MicaWeb.BaseRoutes.live_routes()
    Mica.SaaS.Routes.system_routes(Next.SaaS)
    MicaWeb.BaseRoutes.routes()

They use the pipelines of `MicaWeb.Pipelines`.

# `auth_routes`
*macro* 

The Google, SURFconext and Centerdata sign-in routes.

# `live_routes`
*macro* 

The account pages of `MicaWeb.Live.Routes`, and its test pages in the test build.

# `routes`
*macro* 

The error and API routes, the local image catalog, `/.status/*`,
`/uploads/:filename` and, with e2e support, `/sent_emails`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
