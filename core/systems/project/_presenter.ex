defmodule Systems.Project.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Project
  }

  @impl true
  def view_model(%Project.NodeModel{} = node, page, assigns) do
    builder(page).view_model(node, assigns)
  end

  @impl true
  def view_model(%Project.ItemModel{} = item, page, assigns) do
    builder(page).view_model(item, assigns)
  end

  defp builder(Project.NodePage), do: Project.NodePageBuilder
  defp builder(Project.ItemContentPage), do: Project.ItemContentPageBuilder
end
