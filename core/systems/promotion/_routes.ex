defmodule Systems.Promotion.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Promotion do
        pipe_through([:browser])
        live("/promotion/:id", LandingPage)
      end
    end
  end
end
