defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug
  require Frameworks.E2E.Routes

  Core.BundleOverrides.routes()

  require GoogleSignIn
  GoogleSignIn.routes(:core)

  require SignInWithApple
  SignInWithApple.routes(:core)

  Core.SurfConext.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()
  Frameworks.E2E.Routes.routes()

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/.status/health", HealthController, :get)
    get("/.status/wakeup", WakeupController, :get)
  end

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/uploads/:filename", UploadedFileController, :get)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
