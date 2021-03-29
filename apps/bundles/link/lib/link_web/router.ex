defmodule LinkWeb.Router do
  use LinkWeb, :router

  require GoogleSignIn
  require SignInWithApple
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug

  GoogleSignIn.routes()
  Core.SurfConext.routes()
  SignInWithApple.routes(Application.get_env(:core, SignInWithApple))
  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
