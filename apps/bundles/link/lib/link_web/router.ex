defmodule LinkWeb.Router do
  use LinkWeb, :router

  require GoogleSignIn
  require Core.SurfConext
  require CoreWeb.Routes

  GoogleSignIn.routes()
  Core.SurfConext.routes()
  CoreWeb.Routes.routes()

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
