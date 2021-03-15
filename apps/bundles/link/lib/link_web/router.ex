defmodule LinkWeb.Router do
  use LinkWeb, :router

  require Core.SurfConext
  require CoreWeb.Routes

  Core.SurfConext.routes()
  CoreWeb.Routes.routes()

  if Mix.env() == :dev do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
