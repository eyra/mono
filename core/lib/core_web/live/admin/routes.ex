defmodule CoreWeb.Live.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", CoreWeb.Admin do
        pipe_through([:browser])

        live("/login", Login)
        live("/coordinator-management", CoordinatorManagement)
        live("/support-tickets", SupportTickets)
      end
    end
  end
end
