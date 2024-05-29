defmodule Systems.Project.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Project

  @impl true
  def view_model(Project.NodePage, node, assigns) do
    Project.NodePageBuilder.view_model(node, assigns)
  end

  @impl true
  def view_model(Project.OverviewPage, %Systems.Account.User{} = user, assigns) do
    Project.OverviewPageBuilder.view_model(user, assigns)
  end
end
