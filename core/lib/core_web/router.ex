defmodule CoreWeb.Router do
  use CoreWeb, :router

  alias Frameworks.E2E.Routes

  require Core.BundleOverrides
  require Core.SurfConext
  require CoreWeb.LocalImageCatalogPlug
  require CoreWeb.Routes
  require GoogleSignIn
  require Routes
  require SignInWithApple

  Core.BundleOverrides.routes()

  GoogleSignIn.routes(:core)

  SignInWithApple.routes(:core)

  Core.SurfConext.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()
  Routes.routes()

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/.status/health", HealthController, :get)
    get("/.status/wakeup", WakeupController, :get)
    get("/.status/features", FeaturesController, :get)
  end

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/uploads/:filename", UploadedFileController, :get)
  end

  if Application.compile_env(:core, :enable_e2e_support, false) do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
