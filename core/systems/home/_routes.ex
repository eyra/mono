defmodule Systems.Home.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Home do
        pipe_through([:browser])
        live("/", Page)
        live("/studies", StudiesPage)
      end
    end
  end
end
