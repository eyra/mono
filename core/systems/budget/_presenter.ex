defmodule Systems.Budget.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Budget

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  def builder(Budget.FundingPage), do: Budget.FundingPageBuilder
end
