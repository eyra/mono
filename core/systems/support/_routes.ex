defmodule Systems.Support.Routes do
  defmacro routes() do
    quote do
      scope "/support", Systems.Support do
        pipe_through([:browser])
        live("/ticket", OverviewPage)
        live("/ticket/:id", TicketPage)
        live("/helpdesk", HelpdeskPage)
      end
    end
  end
end
