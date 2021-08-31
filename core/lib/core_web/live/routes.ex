defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      use CoreWeb.Live.Subroutes, [
        :study,
        :helpdesk,
        :data_donation,
        :lab,
        :promotion,
        :user,
        :admin
      ]

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
