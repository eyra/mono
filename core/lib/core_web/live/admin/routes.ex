defmodule CoreWeb.Live.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", CoreWeb.Admin do
        pipe_through([:browser])

        live("/coordinator-management", CoordinatorManagement)
      end
    end
  end
end
