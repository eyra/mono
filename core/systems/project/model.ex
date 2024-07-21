defmodule Systems.Project.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project
  }

  schema "projects" do
    field(:name, :string)
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:root, Project.NodeModel)
    timestamps()
  end

  @required_fields ~w(name)a
  @fields @required_fields

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :root,
        :auth_node
      ])

  def preload_graph(:root), do: [root: Project.NodeModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]

  def auth_tree(%Project.Model{auth_node: auth_node, root: root}) do
    {auth_node, Project.NodeModel.auth_tree(root)}
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(project), do: project.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.Model{} = project, page, %{current_user: user}) do
      vm(project, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name,
             root: %{
               id: root_node_id,
               items: items
             }
           },
           {Project.OverviewPage, :card},
           _user
         ) do
      path = ~p"/project/node/#{root_node_id}"

      people = %{
        action: %{type: :send, event: "setup_people", item: id},
        face: %{type: :label, label: "People", wrap: true}
      }

      rename = %{
        action: %{type: :send, event: "rename", item: id},
        face: %{type: :label, label: "Rename", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      info = [info(items)]

      tags =
        items
        |> Enum.map(&Project.ItemModel.tag/1)
        |> Enum.filter(&(&1 != nil))
        |> Enum.uniq()

      %{
        type: :secondary,
        id: id,
        path: path,
        label: nil,
        title: name,
        tags: tags,
        info: info,
        left_actions: [rename, people],
        right_actions: [delete]
      }
    end

    defp info([_item]), do: "1 item"
    defp info(items) when is_list(items), do: "#{Enum.count(items)} items"
  end
end
