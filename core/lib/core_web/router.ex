defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require GoogleSignIn
  require SignInWithApple
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug

  Core.BundleOverrides.routes()

  GoogleSignIn.routes(:core)
  Core.SurfConext.routes(:core)
  SignInWithApple.routes(:core)
  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()

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
