defmodule CoreWeb.Router do
  use CoreWeb, :router

  require Core.BundleOverrides
  require Systems.Account.Identity.Surfconext
  require CoreWeb.Routes
  require CoreWeb.LocalImageCatalogPlug
  require Frameworks.E2E.Routes

  Core.BundleOverrides.routes()

  require Systems.Account.Identity.Google
  Systems.Account.Identity.Google.routes(:core)

  Systems.Account.Identity.Surfconext.routes(:core)

  CoreWeb.Routes.routes()
  CoreWeb.LocalImageCatalogPlug.routes()
  Frameworks.E2E.Routes.routes()

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

  if Application.compile_env(:core, :enable_e2e_support, false) do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end
end
