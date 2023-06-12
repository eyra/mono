defmodule Systems.Project.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project,
    DataDonation
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

  def preload_graph(:full),
    do:
      preload_graph([
        :root,
        :auth_node
      ])

  def preload_graph(:root),
    do: [
      root: [
        :children,
        :auth_node,
        items: [tool_ref: Project.ToolRefModel.preload_graph(:data_donation_tool)]
      ]
    ]

  def preload_graph(:auth_node), do: [auth_node: []]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(project), do: project.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    def view_model(%Project.Model{} = project, page, user, _url_resolver) do
      vm(project, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name,
             root: %{
               items: [
                 %{
                   tool_ref: %{
                     data_donation_tool: %{
                       subject_count: subject_count,
                       platforms: platforms
                     }
                   }
                 }
               ]
             }
           },
           {Project.OverviewPage, :card},
           _user
         ) do
      tags = get_card_tags(platforms)

      %{
        type: :secondary,
        id: id,
        label: %{type: :warning, text: "Concept"},
        title: name,
        tags: tags,
        info: ["#{subject_count} participants | 0 donations"],
        right_actions: [],
        left_actions: []
      }
    end

    defp get_card_tags(nil), do: []

    defp get_card_tags(platforms) do
      Enum.map(platforms, &DataDonation.Platforms.translate(&1))
    end
  end
end
