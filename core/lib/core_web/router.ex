defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug

  Core.BundleOverrides.routes()

  require GoogleSignIn
  GoogleSignIn.routes(:core)

  require SignInWithApple
  SignInWithApple.routes(:core)

  Core.SurfConext.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/.status/health", HealthController, :get)
  end

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/uploads/:filename", UploadedFileController, :get)
  end

  scope "/", CoreWeb do
    pipe_through([:api, :require_authenticated_user])
    get("/web-push/vapid-public-key", PushSubscriptionController, :vapid_public_key)
    post("/web-push/register", PushSubscriptionController, :register)
  end

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
