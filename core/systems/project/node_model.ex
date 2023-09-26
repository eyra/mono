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

  def preload_graph(:down),
    do:
      preload_graph([
        :children,
        :items,
        :auth_node
      ])

  def preload_graph(:children), do: [children: [:children, :items, :auth_node]]
  def preload_graph(:items), do: [items: Project.ItemModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]

  def auth_tree(%Project.NodeModel{children: %Ecto.Association.NotLoaded{}} = node) do
    auth_tree(Repo.preload(node, :children))
  end

  def auth_tree(%Project.NodeModel{items: %Ecto.Association.NotLoaded{}} = node) do
    auth_tree(Repo.preload(node, :items))
  end

  def auth_tree(%Project.NodeModel{auth_node: auth_node, children: children, items: items}) do
    {auth_node, auth_tree(children) ++ Project.ItemModel.auth_tree(items)}
  end

  def auth_tree(nodes) when is_list(nodes) do
    Enum.map(nodes, &auth_tree/1)
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(project_node), do: project_node.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.NodeModel{} = node, page, %{current_user: user}) do
      vm(node, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name
           },
           {Project.NodePage, :item_card},
           _user
         ) do
      path = ~p"/project/item/#{id}/content"

      %{
        type: :secondary,
        id: id,
        path: path,
        title: name,
        tags: [],
        right_actions: [],
        left_actions: []
      }
    end

    defp vm(
           %{
             id: id,
             name: name
           },
           {Project.NodePage, :node_card},
           _user
         ) do
      path = ~p"/project/node/#{id}"

      %{
        type: :primary,
        id: id,
        path: path,
        title: name,
        tags: [],
        right_actions: [],
        left_actions: []
      }
    end
  end
end
