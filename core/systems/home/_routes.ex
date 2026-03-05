defmodule Systems.Home.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Home do
        pipe_through([:browser])
        live("/", Page)
      end
    end
  end
end
