defmodule Systems.Project.ItemModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Core.ImageHelpers

  alias Systems.{
    Project,
    Assignment,
    Graphite
  }

  schema "project_items" do
    field(:name, :string)
    field(:project_path, {:array, :integer})
    belongs_to(:node, Project.NodeModel)
    belongs_to(:tool_ref, Project.ToolRefModel)
    belongs_to(:assignment, Assignment.Model)
    belongs_to(:leaderboard, Graphite.LeaderboardModel)
    timestamps()
  end

  @required_fields ~w(name project_path)a
  @fields @required_fields

  @doc false
  def changeset(project_item, attrs) do
    project_item
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:up),
    do:
      preload_graph([
        :node
      ])

  def preload_graph(:down),
    do:
      preload_graph([
        :tool_ref,
        :assignment,
        :leaderboard
      ])

  def preload_graph(:node), do: [node: [:parent, :children, :items, :auth_node]]
  def preload_graph(:tool_ref), do: [tool_ref: Project.ToolRefModel.preload_graph(:down)]
  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]

  def preload_graph(:leaderboard),
    do: [leaderboard: Graphite.LeaderboardModel.preload_graph(:down)]

  def special(%{tool_ref: %{id: _id} = special}), do: special
  def special(%{assignment: %{id: _id} = special}), do: special

  def auth_tree(%Project.ItemModel{tool_ref: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :tool_ref))
  end

  def auth_tree(%Project.ItemModel{tool_ref: tool_ref}) when not is_nil(tool_ref) do
    Project.ToolRefModel.auth_tree(tool_ref)
  end

  def auth_tree(%Project.ItemModel{assignment: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :assignment))
  end

  def auth_tree(%Project.ItemModel{assignment: assignment}) when not is_nil(assignment) do
    Assignment.Model.auth_tree(assignment)
  end

  def auth_tree(%Project.ItemModel{leaderboard: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :leaderboard))
  end

  def auth_tree(%Project.ItemModel{leaderboard: leaderboard}) when not is_nil(leaderboard) do
    Graphite.LeaderboardModel.auth_tree(leaderboard)
  end

  def auth_tree(items) when is_list(items) do
    Enum.map(items, &auth_tree/1)
  end

  def tag(%{tool_ref: %{id: _} = tool_ref}), do: Project.ToolRefModel.tag(tool_ref)
  def tag(%{assignment: %{id: _} = assignment}), do: Assignment.Model.tag(assignment)

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.ItemModel{} = item, page, %{current_user: user}) do
      vm(item, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name,
             assignment:
               %{
                 id: assignment_id,
                 status: status,
                 info: %{
                   subject_count: subject_count,
                   image_id: image_id,
                   logo_url: logo_url
                 }
               } = assignment
           },
           {Project.NodePage, :item_card},
           _user
         ) do
      image_info = ImageHelpers.get_image_info(image_id, 400, 200)
      tags = get_card_tags(assignment)
      path = ~p"/assignment/#{assignment_id}/content"

      edit = %{
        action: %{type: :send, event: "edit", item: id},
        face: %{type: :label, label: "Edit", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      %{
        type: :secondary,
        id: id,
        path: path,
        image_info: image_info,
        icon_url: logo_url,
        label: get_label(status),
        title: name,
        tags: tags,
        info: ["#{subject_count} participants  |  0 donations"],
        left_actions: [edit],
        right_actions: [delete]
      }
    end

    defp vm(
           %{
             id: id,
             name: name,
             tool_ref: %{
               graphite_tool:
                 %{
                   id: graphite_id,
                   status: status,
                   director: _director,
                   spots: spots,
                   leaderboards: _leaderboards
                 } = tool
             }
           },
           {Project.NodePage, :item_card},
           _user
         ) do
      tags = get_card_tags(tool)
      path = ~p"/graphite/#{graphite_id}/content"
      label = get_label(status)

      edit = %{
        action: %{type: :send, event: "edit", item: id},
        face: %{type: :label, label: "Edit", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      team_info = dngettext("eyra-graphite", "1 team", "%{count} teams", Enum.count(spots))

      submission_info =
        dngettext(
          "eyra-graphite",
          "1 submission",
          "%{count} submissions",
          count_submissions(spots)
        )

      info_line_1 = "#{team_info}  |  #{submission_info}"

      %{
        type: :secondary,
        id: id,
        path: path,
        label: label,
        title: name,
        tags: tags,
        info: [info_line_1],
        left_actions: [edit],
        right_actions: [delete]
      }
    end

    defp vm(
           %{
             id: id,
             name: name,
             leaderboard: %{id: _leaderboard_id, status: status} = leaderboard
           },
           {Project.NodePage, :item_card},
           _user
         ) do
      edit = %{
        action: %{type: :send, event: "edit", item: id},
        face: %{type: :label, label: "Edit", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      %{
        type: :secondary,
        id: id,
        path: ~p"/",
        label: get_label(status),
        title: name,
        tags: get_card_tags(leaderboard),
        info: ["Something more meaningful here"],
        left_actions: [edit],
        right_actions: [delete]
      }
    end

    defp count_submissions(spots) when is_list(spots) do
      Enum.reduce(spots, 0, fn spot, acc -> acc + count_submissions(spot) end)
    end

    defp count_submissions(%{submissions: submissions}) do
      Enum.count(submissions)
    end

    defp get_label(:concept),
      do: %{type: :warning, text: dgettext("eyra-project", "label.concept")}

    defp get_label(:online), do: %{type: :success, text: dgettext("eyra-project", "label.online")}

    defp get_label(:offline),
      do: %{type: :delete, text: dgettext("eyra-project", "label.offline")}

    defp get_label(:idle), do: %{type: :idle, text: dgettext("eyra-project", "label.idle")}

    defp get_label(nil), do: %{type: :idle, text: "Improper label"}

    defp get_card_tags(%Assignment.Model{}) do
      ["Assignment"]
    end

    defp get_card_tags(%Graphite.LeaderboardModel{}), do: ["Leaderboard"]
    defp get_card_tags(%Graphite.ToolModel{}), do: ["Challenge"]
    defp get_card_tags(_), do: []
  end
end
