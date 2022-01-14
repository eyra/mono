defmodule Systems.Home.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Home do
        pipe_through([:browser])
        get("/", LandingPage, :show)
      end
    end
  end
end
