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

      if Mix.env() in [:test] do
        scope "/test", Systems.Test do
          pipe_through(:browser)
          live("/page/:id", Page)
        end
      end
    end
  end
end
