defmodule CoreWeb.Router do
  use CoreWeb, :router

  require GoogleSignIn
  require SignInWithApple
  require Core.SurfConext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug

  GoogleSignIn.routes(:core)
  Core.SurfConext.routes(:core)
  SignInWithApple.routes(:core)
  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
