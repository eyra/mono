defmodule MicaSaasWeb.Router do
  @moduledoc """
  Self's router: Mica's pipelines and routes and those of Self's systems, in
  Self's order. The route snapshot (`mix nova.snapshot`) shows any change.
  """

  use MicaSaasWeb, :router

  require MicaWeb.Pipelines
  require Mica.SaaS.Routes
  require MicaWeb.BaseRoutes

  MicaWeb.Pipelines.define()
  # Self's sign-in pages first, so they shadow Mica's paths.
  Mica.SaaS.Routes.override_routes(MicaSaas.SaaS)
  MicaWeb.BaseRoutes.auth_routes()
  MicaWeb.BaseRoutes.live_routes()
  Mica.SaaS.Routes.system_routes(MicaSaas.SaaS)
  MicaWeb.BaseRoutes.routes()

  # Checks every Mica path (`~m`) against this router.
  use MicaWeb.PathCheck
end
