defmodule Systems.Project.Factories do
  alias Core.Factories
  alias Systems.Project
  alias Systems.Alliance
  alias Systems.Assignment
  alias Systems.Graphite

  def build_project() do
    Factories.build(:project, %{name: "project"})
  end

  def build_project(node) do
    Factories.build(:project, %{name: "project", node: node})
  end

  def build_node(), do: build_node([])

  def build_node(arguments) when is_list(arguments) do
    {items, arguments} = Keyword.pop(arguments, :items, [])
    {children, _arguments} = Keyword.pop(arguments, :children, [])

    Factories.build(:project_node, %{
      name: "project-node",
      project_path: [],
      items: items,
      children: children
    })
  end

  def build_node(_, arguments \\ [])

  def build_node(%Project.ItemModel{} = item, arguments) do
    arguments = Keyword.update(arguments, :items, [item], &(&1 ++ [item]))
    build_node(arguments)
  end

  def build_node(%Project.NodeModel{} = child, arguments) do
    arguments = Keyword.update(arguments, :children, [child], &(&1 ++ [child]))
    build_node(arguments)
  end

  def build_item(_, name \\ "project-item")

  def build_item(%Assignment.Model{} = assignment, name) do
    Factories.build(:project_item, %{
      name: name,
      project_path: [],
      assignment: assignment
    })
  end

  def build_item(%Graphite.LeaderboardModel{} = leaderboard, name) do
    Factories.build(:project_item, %{
      name: name,
      project_path: [],
      leaderboard: leaderboard
    })
  end

  def build_tool_ref(%Alliance.ToolModel{} = tool) do
    Factories.build(:tool_ref, %{
      alliance_tool: tool
    })
  end

  def build_tool() do
    Factories.build(:alliance_tool, %{
      url: "https://eyra.co/alliance/123",
      director: :assignment
    })
  end

  def build_assignment() do
    Factories.build(:assignment)
  end
end
