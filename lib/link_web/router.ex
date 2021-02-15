defmodule LinkWeb.Router do
  use LinkWeb, :router
  use Pow.Phoenix.Router
  use PowAssent.Phoenix.Router
  require LinkWeb.Cldr

  pipeline :browser_base do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, {LinkWeb.LayoutView, :root}

    plug Cldr.Plug.SetLocale,
      apps: [cldr: LinkWeb.Cldr, gettext: :global],
      from: [:query, :cookie, :accept_language],
      param: "locale"

    plug LinkWeb.Plug.LiveLocale

    plug :fetch_live_flash
  end

  pipeline :browser_secure do
    # Documentation on the `put_secure_browser_headers` plug function
    # can be found here:
    # https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_secure_browser_headers/2
    # Information about the content-security-policy can be found at:
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
    plug :put_secure_browser_headers

    # Disabled CSP for now, Safari has issues with web-sockets and "self" (https://bugs.webkit.org/show_bug.cgi?id=201591)
    # , %{
    #   "content-security-policy" =>
    #     "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; font-src 'self' data:"
    # }
  end

  pipeline :browser do
    plug :browser_base
    plug :protect_from_forgery
    plug :browser_secure
  end

  pipeline :browser_unprotected do
    plug :browser_base
    plug :browser_secure
  end

  pipeline :require_authenticated do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LinkWeb do
    pipe_through :browser
    live "/", Index

    live "/user/signin", User.Signin
    live "/user/signup", User.Signup

    get "/switch-language/:locale", LanguageSwitchController, :index
    live "/fake_survey", FakeSurvey
  end

  scope "/" do
    pipe_through :browser_unprotected
    pow_assent_authorization_post_callback_routes()
  end

  scope "/" do
    pipe_through [:browser]

    scope "/", Pow.Phoenix, as: "pow" do
      post "/session", SessionController, :create
      delete "/session", SessionController, :delete

      post "/registration", RegistrationController, :create
    end

    pow_assent_routes()
  end

  scope "/", LinkWeb do
    pipe_through [:browser, :require_authenticated]

    live "/dashboard", Dashboard

    live "/user/profile", User.Profile

    live "/survey-tools", SurveyTool.Index
    live "/survey-tools/new", SurveyTool.New
    live "/survey-tools/:id", SurveyTool.Edit

    live "/studies/new", Study.New
    live "/studies/:id", Study.Public
    live "/studies/:id/edit", Study.Edit
    live "/studies/:id/complete", Study.Complete
  end

  # Other scopes may use custom stacks.
  # scope "/api", LinkWeb do
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
      pipe_through :browser
      live_dashboard "/phoenix-dashboard", metrics: LinkWeb.Telemetry
    end
  end
end
