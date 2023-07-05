defmodule Systems.Project.Presenter do
  use Systems.Presenter

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

  @impl true
  def view_model(%{id: id}, page, assigns) do
    view_model(id, page, assigns)
  end

  @impl true
  def view_model(id, Project.NodePage = page, assigns) when is_number(id) do
    Project.Public.get_node!(id, Project.NodeModel.preload_graph(:down))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(id, Project.ItemContentPage = page, assigns) when is_number(id) do
    Project.Public.get_item!(id, Project.ItemModel.preload_graph(:down))
    |> view_model(page, assigns)
  end

  defp builder(Project.NodePage), do: Project.NodePageBuilder
  defp builder(Project.ItemContentPage), do: Project.ContentPageBuilder.Item
end
