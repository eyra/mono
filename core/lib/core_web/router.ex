defmodule CoreWeb.Router do
  use CoreWeb, :router
  import Core.FeatureFlags

  require Core.BundleOverrides
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug

  Core.BundleOverrides.routes()

  if feature_enabled?(:google_sign_in) do
    require GoogleSignIn
    GoogleSignIn.routes(:core)
  end

  if feature_enabled?(:sign_in_with_apple) do
    require SignInWithApple
    SignInWithApple.routes(:core)
  end

  Core.SurfConext.routes(:core)

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
