defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require Core.Env
  require Systems.Account.Auth.Surfconext
  require Systems.Account.Auth.Centerdata
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug
  require Frameworks.E2E.Routes
  require PhoenixStorybook.Router

  Core.BundleOverrides.routes()

  require Systems.Account.Auth.Google
  Systems.Account.Auth.Google.routes(:core)

  Systems.Account.Auth.Surfconext.routes(:core)
  Systems.Account.Auth.Centerdata.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()
  Frameworks.E2E.Routes.routes()

  scope "/" do
    PhoenixStorybook.Router.storybook_assets()
  end

  scope "/" do
    pipe_through([:browser, CoreWeb.StorybookGuard])

    # An atom, not an alias: an alias makes the router (and every file compile-connected to it)
    # recompile whenever a story is added or removed.
    PhoenixStorybook.Router.live_storybook("/storybook",
      backend_module: :"Elixir.CoreWeb.Storybook"
    )
  end

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/.status/health", HealthController, :get)
    get("/.status/wakeup", WakeupController, :get)
    get("/.status/features", FeaturesController, :get)
  end

  scope "/", CoreWeb do
    pipe_through([:browser_base])
    get("/uploads/:filename", UploadedFileController, :get)
  end

  if Core.Env.compile_env(:enable_e2e_support, false) do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
