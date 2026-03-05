defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require Core.SurfConext
  require CoreWeb.LocalImageCatalogPlug
  require CoreWeb.Routes
  require GoogleSignIn
  require SignInWithApple

  Core.BundleOverrides.routes()

  GoogleSignIn.routes(:core)

  SignInWithApple.routes(:core)

  Core.SurfConext.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()

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
