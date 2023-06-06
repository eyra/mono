defmodule Systems.Project.NodeModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project
  }

  schema "project_nodes" do
    field(:name, :string)
    field(:project_path, {:array, :integer})
    field(:parent_id, :integer)
    belongs_to(:parent, __MODULE__, foreign_key: :parent_id, references: :id, define_field: false)
    has_many(:children, __MODULE__, foreign_key: :parent_id)
    has_many(:items, Project.ItemModel, foreign_key: :node_id)
    belongs_to(:auth_node, Core.Authorization.Node)
    timestamps()
  end

  @required_fields ~w(name project_path)a
  @fields @required_fields

  @doc false
  def changeset(project_node, attrs) do
    project_node
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :children,
        :items,
        :auth_node
      ])

  def preload_graph(:parent), do: [parent: [:parent, :children, :items, :auth_node]]
  def preload_graph(:children), do: [children: [:children, :items, :auth_node]]
  def preload_graph(:items), do: [items: [:tool_ref]]
  def preload_graph(:auth_node), do: [auth_node: []]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(project_node), do: project_node.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    def view_model(%Project.Model{} = project, page, user, _url_resolver) do
      vm(project, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name
           },
           {Project.OverviewPage, :card},
           _user
         ) do
      %{
        type: :primary,
        id: id,
        title: name,
        tags: [],
        right_actions: [],
        left_actions: []
      }
    end
  end
end
