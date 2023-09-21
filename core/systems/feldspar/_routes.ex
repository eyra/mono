defmodule Systems.Feldspar.Routes do
  defmacro routes() do
    quote do
      scope "/apps", Systems.Feldspar do
        pipe_through([:browser])
        live("/:id", AppPage)
      end
    end
  end
end
