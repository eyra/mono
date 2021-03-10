defmodule LinkWeb.Router do
  use LinkWeb, :router

  require CoreWeb.Cldr
  import CoreWeb.UserAuth
  alias Core.SurfConext
  require Core.SurfConext

  pipeline :browser_base do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {CoreWeb.LayoutView, :root})

    plug(Cldr.Plug.SetLocale,
      apps: [cldr: CoreWeb.Cldr, gettext: :global],
      from: [:query, :cookie, :accept_language],
      param: "locale"
    )

    plug(CoreWeb.Plug.LiveLocale)

    plug(:fetch_live_flash)
  end

  pipeline :browser_secure do
    # Documentation on the `put_secure_browser_headers` plug function
    # can be found here:
    # https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_secure_browser_headers/2
    # Information about the content-security-policy can be found at:
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)

    # Disabled CSP for now, Safari has issues with web-sockets and "self" (https://bugs.webkit.org/show_bug.cgi?id=201591)
    # , %{
    #   "content-security-policy" =>
    #     "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; font-src 'self' data:"
    # }
  end

  pipeline :browser do
    plug(:browser_base)
    plug(:protect_from_forgery)
    plug(:browser_secure)
  end

  pipeline :browser_unprotected do
    plug(:browser_base)
    plug(:browser_secure)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  ## Authentication routes

  SurfConext.routes(Application.fetch_env!(:link, SurfConext))

  scope "/", CoreWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live("/user/signup", User.Signup)
    live("/user/confirm/:token", User.ConfirmToken)
    live("/user/confirm", User.ConfirmToken)
    live("/user/await-confirmation", User.AwaitConfirmation)
    get("/user/signin", UserSessionController, :new)
    post("/user/signin", UserSessionController, :create)
    live("/user/reset-password", User.ResetPassword)
    live("/user/reset-password/:token", User.ResetPasswordToken)
  end

  ## User routes

  scope "/", CoreWeb do
    pipe_through([:browser, :require_authenticated_user])

    live("/user/profile", User.Profile)
    get("/user/settings", UserSettingsController, :edit)
    put("/user/settings", UserSettingsController, :update)
    get("/user/settings/confirm-email/:token", UserSettingsController, :confirm_email)
  end

  scope "/", CoreWeb do
    pipe_through([:browser])
    delete("/user/signout", UserSessionController, :delete)
  end

  scope "/", CoreWeb do
    pipe_through(:browser)
    live("/", Index)

    get("/switch-language/:locale", LanguageSwitchController, :index)
    live("/fake_survey", FakeSurvey)
  end

  scope "/", CoreWeb do
    pipe_through([:browser, :require_authenticated_user])

    live("/dashboard", Dashboard)

    live("/survey-tools", SurveyTool.Index)
    live("/survey-tools/new", SurveyTool.New)
    live("/survey-tools/:id", SurveyTool.Edit)

    live("/studies/new", Study.New)
    live("/studies/:id", Study.Public)
    live("/studies/:id/edit", Study.Edit)
    live("/studies/:id/complete", Study.Complete)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CoreWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/phoenix-dashboard", metrics: CoreWeb.Telemetry)
    end
  end
end
