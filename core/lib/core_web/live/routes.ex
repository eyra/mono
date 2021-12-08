defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      use CoreWeb.Live.Subroutes, [
        :study,
        :data_donation,
        :lab,
        :user
      ]

      scope "/", CoreWeb do
        pipe_through(:browser)
        get("/switch-language/:locale", LanguageSwitchController, :index)
        live("/fake_survey/:id", FakeSurvey)
      end

      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])
        live("/onboarding", Onboarding)
        live("/dashboard", Dashboard)
      end

      if Mix.env() in [:dev, :test] do
        import Phoenix.LiveDashboard.Router

        scope "/" do
          pipe_through(:browser)
          live_dashboard("/phoenix-dashboard", metrics: CoreWeb.Telemetry)
        end
      end

      if Mix.env() in [:test] do
        scope "/test", Systems.Test do
          pipe_through(:browser)
          live("/page/:id", Page)
        end
      end
    end
  end
end
