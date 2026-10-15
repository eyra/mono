defmodule Systems.Org.Routes do
  defmacro routes() do
    quote do
      scope "/org", Systems.Org do
        pipe_through([:browser])

        live("/node/:id", ContentPage)
      end
    end
  end
end
