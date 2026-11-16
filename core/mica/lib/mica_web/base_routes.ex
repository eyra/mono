defmodule MicaWeb.BaseRoutes do
  @moduledoc """
  Mica's routes that belong to no system, for a SaaS router. The router puts
  them in its own order, around the systems' routes (`Mica.SaaS.Routes`):

      MicaWeb.Pipelines.define()
      Mica.SaaS.Routes.override_routes(Next.SaaS)
      MicaWeb.BaseRoutes.auth_routes()
      MicaWeb.BaseRoutes.live_routes()
      Mica.SaaS.Routes.system_routes(Next.SaaS)
      MicaWeb.BaseRoutes.routes()

  They use the pipelines of `MicaWeb.Pipelines`.
  """

  @doc "The Google, SURFconext and Centerdata sign-in routes."
  defmacro auth_routes do
    quote do
      require Systems.Account.Auth.Google
      require Systems.Account.Auth.Surfconext
      require Systems.Account.Auth.Centerdata

      Systems.Account.Auth.Google.routes(:mica)
      Systems.Account.Auth.Surfconext.routes(:mica)
      Systems.Account.Auth.Centerdata.routes(:mica)
    end
  end

  @doc "The account pages of `MicaWeb.Live.Routes`, and its test pages in the test build."
  defmacro live_routes do
    quote do
      require MicaWeb.Live.Routes
      MicaWeb.Live.Routes.routes()
    end
  end

  @doc """
  The error and API routes, the local image catalog, `/.status/*`,
  `/uploads/:filename` and, with e2e support, `/sent_emails`.
  """
  defmacro routes do
    quote do
      require Mica.Env
      require MicaWeb.LocalImageCatalogPlug

      scope "/", MicaWeb do
        pipe_through(:browser_unprotected)
        get("/access_denied", ErrorController, :access_denied)
        get("/not_found", ErrorController, :not_found)
      end

      scope "/", MicaWeb do
        pipe_through(:api)

        post("/api/viewport", ViewportController, :put_session)
      end

      MicaWeb.LocalImageCatalogPlug.routes()

      scope "/", MicaWeb do
        pipe_through([:browser_base])
        get("/.status/health", HealthController, :get)
        get("/.status/wakeup", WakeupController, :get)
        get("/.status/features", FeaturesController, :get)
      end

      scope "/", MicaWeb do
        pipe_through([:browser_base])
        get("/uploads/:filename", UploadedFileController, :get)
      end

      if Mica.Env.compile_env(:enable_e2e_support, false) do
        forward("/sent_emails", Bamboo.SentEmailViewerPlug)
      end
    end
  end
end
