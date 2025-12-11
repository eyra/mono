defmodule CoreWeb.Live.Routes do
  defmacro routes() do
    quote do
      use CoreWeb.Live.Subroutes, [
        :user
      ]

      scope "/", CoreWeb do
        pipe_through(:browser)
        live("/fake_qualtrics", FakeQualtrics)
      end

      if Mix.env() in [:dev] do
        scope "/", CoreWeb do
          pipe_through(:browser)
          live("/component_test", ComponentTestLive)
          live("/component_test/:component", ComponentTestLive)
        end
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
