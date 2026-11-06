defmodule MicaWeb.Live.Routes do
  defmacro routes() do
    quote do
      use MicaWeb.Live.Subroutes, [
        :user
      ]

      scope "/", MicaWeb do
        pipe_through(:browser)
        live("/fake_qualtrics", FakeQualtrics)
      end

      if Mix.env() in [:test] do
        scope "/test", Systems.Test do
          pipe_through(:browser)
          live("/page/:id", Page)
          live("/routed/:id", RoutedLiveView)
        end
      end
    end
  end
end
