defmodule CoreWeb.Live.Helpdesk.Routes do
  defmacro routes() do
    quote do
      scope "/helpdesk", CoreWeb.Helpdesk do
        pipe_through([:browser])

        live("/", Public)
        live("/admin", Admin)
      end
    end
  end
end
