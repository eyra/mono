defmodule Systems.Project.ItemModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
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
        :assignment,
        :leaderboard
      ])

  def preload_graph(:node), do: [node: [:parent, :children, :items, :auth_node]]
  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]

  def preload_graph(:leaderboard),
    do: [leaderboard: Graphite.LeaderboardModel.preload_graph(:down)]

  def special(%{assignment: %{id: _id} = special}), do: special

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

  def tag(%{assignment: %{id: _} = assignment}), do: Assignment.Model.tag(assignment)
  def tag(%{leaderboard: %{id: _} = leaderboard}), do: Graphite.LeaderboardModel.tag(leaderboard)

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.ItemModel{} = item, page, %{current_user: user, timezone: timezone}) do
      vm(item, page, user, timezone)
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
                   image_id: image_id,
                   logo_url: logo_url
                 }
               } = assignment
           },
           {Project.NodePage, :item_card},
           _user,
           _timezone
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
        info: get_assignment_info(assignment),
        left_actions: [edit],
        right_actions: [delete]
      }
    end

    defp vm(
           %{
             id: id,
             name: name,
             leaderboard: %{id: leaderboard_id, status: status} = leaderboard
           },
           {Project.NodePage, :item_card},
           _user,
           timezone
         ) do
      assignment = Assignment.Public.get_by_tool(leaderboard.tool, [:info])
      image_info = ImageHelpers.get_image_info(assignment.info.image_id, 400, 200)
      logo_url = assignment.info.logo_url

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
        path: ~p"/graphite/leaderboard/#{leaderboard_id}/content",
        image_info: image_info,
        icon_url: logo_url,
        label: get_label(status),
        title: name,
        tags: get_card_tags(leaderboard),
        info: get_leaderboard_info(leaderboard, timezone),
        left_actions: [edit],
        right_actions: [delete]
      }
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

    defp get_assignment_info(%Assignment.Model{info: info}) do
      subject_count = Map.get(info, :subject_count) || 0
      [dgettext("eyra-project", "assignment.participant.info", count: subject_count)]
    end

    defp get_leaderboard_info(%Graphite.LeaderboardModel{id: _id, tool: tool}, timezone) do
      deadline_str = format_datetime(tool.deadline, timezone)
      nr_submissions = Graphite.Public.get_submission_count(tool)

      submission_info =
        dgettext("eyra-project", "leaderboard.submission.info", count: nr_submissions)

      deadline_info =
        dgettext("eyra-project", "leaderboard.deadline.info", deadline: deadline_str)

      [
        [submission_info, deadline_info]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("  |  ")
      ]
    end

    defp format_datetime(nil, _timezone),
      do: dgettext("eyra-project", "leaderboard.unspecified.label")

    defp format_datetime(_, nil), do: ""

    defp format_datetime(datetime, timezone) do
      datetime
      |> Timestamp.convert(timezone)
      |> Timestamp.format!()
    end
  end
end
