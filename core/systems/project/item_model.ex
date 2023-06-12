defmodule Systems.Project.ItemModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project
  }

  schema "project_items" do
    field(:project_path, {:array, :integer})
    belongs_to(:node, Project.NodeModel)
    belongs_to(:tool_ref, Project.ToolRefModel)
    timestamps()
  end

  @required_fields ~w(project_path)a
  @fields @required_fields

  @doc false
  def changeset(project_item, attrs) do
    project_item
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :node,
        :tool_ref
      ])

  def preload_graph(:node), do: [node: [:parent, :children, :items, :auth_node]]
  def preload_graph(:tool_ref), do: [tool_ref: [:survey_tool, :lab_tool, :data_donation_tool]]
end
