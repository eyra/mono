defmodule MicaWeb.Router do
  use MicaWeb, :router

  require Mica.SaaS
  require Mica.Env
  require Systems.Account.Auth.Surfconext
  require Systems.Account.Auth.Centerdata
  require MicaWeb.Routes
  require MicaWeb.LocalImageCatalogPlug

  # The routes come from the systems of the configured SaaS, so the router is
  # compiled against `config :mica, saas:`. Mix does not recompile when only an
  # env var (BUNDLE) changed the value; this recompiles the router.
  @saas Mica.Env.compile_env(:saas)
  def __mix_recompile__?, do: Mica.Env.get(:saas) != @saas

  Mica.SaaS.override_routes()

  require Systems.Account.Auth.Google
  Systems.Account.Auth.Google.routes(:mica)

  Systems.Account.Auth.Surfconext.routes(:mica)
  Systems.Account.Auth.Centerdata.routes(:mica)

  MicaWeb.Routes.routes()
  MicaWeb.LocalImageCatalogPlug.routes()

  scope "/", MicaWeb do
    pipe_through([:browser_base])
    get("/.status/health", HealthController, :get)
    get("/.status/wakeup", WakeupController, :get)
    get("/.status/features", FeaturesController, :get)
  end

  scope "/", MicaWeb do
    pipe_through([:browser_base])
    get("/uploads/:filename", UploadedFileController, :get)
  end

  if Mica.Env.compile_env(:enable_e2e_support, false) do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  # Checks every Mica path (`~m`) against this router. Moves to each SaaS's
  # router once Mica's is gone (code-compose PR 8).
  use MicaWeb.PathCheck
end
