defmodule CoreWeb.Support.Router do
  use CoreWeb, :router

  require GoogleSignIn
  require SignInWithApple
  require Core.SurfConext
  require CoreWeb.Routes

  GoogleSignIn.routes()
  SignInWithApple.routes(Application.get_env(:core, SignInWithApple))
  Core.SurfConext.routes()
  CoreWeb.Routes.routes()
end
