defmodule Systems.Support.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Support.Routes
      Systems.Support.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Support.HelpdeskPage, [:member]},
        {Systems.Support.OverviewPage, [:admin]},
        {Systems.Support.TicketPage, [:admin]}
      ]
    end
  end
end
