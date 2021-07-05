defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      require CoreWeb.Live.Study.Routes
      require CoreWeb.Live.Survey.Routes
      require CoreWeb.Live.DataDonation.Routes
      require CoreWeb.Live.Promotion.Routes
      require CoreWeb.Live.User.Routes

      CoreWeb.Live.Study.Routes.routes()
      CoreWeb.Live.Survey.Routes.routes()
      CoreWeb.Live.DataDonation.Routes.routes()
      CoreWeb.Live.Promotion.Routes.routes()
      CoreWeb.Live.User.Routes.routes()

      scope "/", CoreWeb do
        pipe_through(:browser)
        live("/", Index)

        get("/switch-language/:locale", LanguageSwitchController, :index)
        live("/fake_survey", FakeSurvey)
      end

      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])
        live("/dashboard", Dashboard)
        live("/notifications", Notifications)
      end

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
  end
end
