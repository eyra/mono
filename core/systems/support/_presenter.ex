defmodule Systems.Support.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Support

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  def builder(Support.HelpdeskPage), do: Support.HelpdeskPageBuilder
  def builder(Support.TicketPage), do: Support.TicketPageBuilder
  def builder(Support.OverviewPage), do: Support.OverviewPageBuilder
end
