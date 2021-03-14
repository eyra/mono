defmodule CoreWeb.Support.Router do
  use CoreWeb, :router

  require Core.SurfConext
  require CoreWeb.Routes

  CoreWeb.Routes.routes()
  Core.SurfConext.routes()
end
