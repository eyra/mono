defmodule NextWeb.Router do
  @moduledoc """
  Next's router: Mica's pipelines and routes and those of Next's systems, in
  Next's order. The route snapshot (`mix nova.snapshot`) shows any change.
  """

  use NextWeb, :router

  require MicaWeb.Pipelines
  require Mica.SaaS.Routes
  require MicaWeb.BaseRoutes

  MicaWeb.Pipelines.define()
  # Next's sign-in pages first, so they shadow Mica's paths.
  Mica.SaaS.Routes.override_routes(Next.SaaS)
  MicaWeb.BaseRoutes.auth_routes()
  MicaWeb.BaseRoutes.live_routes()
  Mica.SaaS.Routes.system_routes(Next.SaaS)
  MicaWeb.BaseRoutes.routes()

  # Checks every Mica path (`~m`) against this router.
  use MicaWeb.PathCheck
end
