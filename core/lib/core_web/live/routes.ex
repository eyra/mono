defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      require CoreWeb.Live.Study.Routes
      require CoreWeb.Live.DataDonation.Routes
      require CoreWeb.Live.Lab.Routes
      require CoreWeb.Live.Promotion.Routes
      require CoreWeb.Live.User.Routes
      require CoreWeb.Live.Admin.Routes

      CoreWeb.Live.Study.Routes.routes()
      CoreWeb.Live.DataDonation.Routes.routes()
      CoreWeb.Live.Lab.Routes.routes()
      CoreWeb.Live.Promotion.Routes.routes()
      CoreWeb.Live.User.Routes.routes()
      CoreWeb.Live.Admin.Routes.routes()

      scope "/", CoreWeb do
        pipe_through(:browser)
        live("/", Index)

        get("/switch-language/:locale", LanguageSwitchController, :index)
        live("/fake_survey", FakeSurvey)
      end

      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])
        live("/onboarding", Onboarding)
        live("/dashboard", Dashboard)
        live("/marketplace", Marketplace)
        live("/todo", Todo)
        live("/notifications", Notifications)
      end

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
