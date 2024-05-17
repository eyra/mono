defmodule Systems.Console.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Console do
        pipe_through([:browser, :require_authenticated_user])
        live("/console", Page)
      end
    end
  end
end
