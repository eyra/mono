defmodule Systems.NextAction.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.NextAction

  @impl true
  def view_model(NextAction.OverviewPage, user, assigns) do
    NextAction.OverviewPageBuilder.view_model(user, assigns)
  end
end
