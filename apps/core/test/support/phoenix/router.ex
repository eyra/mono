defmodule CoreWeb.Support.Router do
  use CoreWeb, :router

  require GoogleSignIn
  require SignInWithApple
  require Core.SurfConext
  require CoreWeb.Routes

  GoogleSignIn.routes(:core)
  SignInWithApple.routes(:core)
  Core.SurfConext.routes(:core)
  CoreWeb.Routes.routes()
end
