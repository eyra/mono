defmodule Systems.Project.ItemModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.{
    Project,
    DataDonation,
    Benchmark
  }

  schema "project_items" do
    field(:name, :string)
    field(:project_path, {:array, :integer})
    belongs_to(:node, Project.NodeModel)
    belongs_to(:tool_ref, Project.ToolRefModel)
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

  def preload_graph(:down),
    do:
      preload_graph([
        :node,
        :tool_ref
      ])

  def preload_graph(:node), do: [node: [:parent, :children, :items, :auth_node]]
  def preload_graph(:tool_ref), do: [tool_ref: Project.ToolRefModel.preload_graph(:down)]

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.ItemModel{} = item, page, %{current_user: user}) do
      vm(item, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name,
             tool_ref: %{
               data_donation_tool:
                 %{
                   subject_count: subject_count
                 } = tool
             }
           },
           {Project.NodePage, :item_card},
           _user
         ) do
      tags = get_card_tags(tool)
      path = ~p"/project/item/#{id}/content"

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
        label: get_label(:concept),
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
               benchmark_tool:
                 %{
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
      path = ~p"/project/item/#{id}/content"
      label = get_label(status)

      edit = %{
        action: %{type: :send, event: "edit", item: id},
        face: %{type: :label, label: "Edit", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      team_info = dngettext("eyra-benchmark", "1 team", "%{count} teams", Enum.count(spots))

      submission_info =
        dngettext(
          "eyra-benchmark",
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

    defp get_card_tags(%DataDonation.ToolModel{tasks: tasks}) when is_list(tasks) do
      tasks
      |> Enum.map(& &1.platform)
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.map(&DataDonation.Platforms.translate/1)
    end

    defp get_card_tags(%Benchmark.ToolModel{}), do: ["Challenge"]
    defp get_card_tags(_), do: []
  end
end
