defmodule Systems.Onyx.Routes do
  defmacro routes() do
    quote do
      scope "/" do
        pipe_through([:browser])

        live("/onyx", Systems.Onyx.LandingPage)
      end
    end
  end
end
