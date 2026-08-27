defmodule Systems.Support.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Support do
        pipe_through([:browser])
        live("/support/ticket", OverviewPage)
        live("/support/ticket/:id", TicketPage)
        live("/support/helpdesk", HelpdeskPage)
      end
    end
  end
end
