defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      use CoreWeb.Live.Subroutes, [
        :user
      ]

      scope "/", CoreWeb do
        pipe_through(:browser)
        get("/switch-language/:locale", LanguageSwitchController, :index)
        live("/fake_survey/:id", FakeQuestionnaire)
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
