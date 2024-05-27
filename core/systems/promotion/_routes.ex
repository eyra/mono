defmodule Systems.Promotion.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Promotion do
        pipe_through([:browser])
        live("/promotion/:id", LandingPage)
      end
    end
  end
end
