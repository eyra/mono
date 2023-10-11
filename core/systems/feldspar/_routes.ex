defmodule Systems.Feldspar.Routes do
  defmacro routes() do
    quote do
      scope "/feldspar", Systems.Feldspar do
        pipe_through([:browser])
        live("/apps/:id", AppPage)
      end
    end
  end
end
