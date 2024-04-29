defmodule Systems.Graphite.ToolModel do
  @moduledoc """
  The benchmark tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.Graphite
  alias Systems.Workflow
  alias CoreWeb.UI.Timestamp

  schema "graphite_tools" do
    field(:deadline, :utc_datetime)
    field(:deadline_string, :string, virtual: true)

    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:submissions, Graphite.SubmissionModel, foreign_key: :tool_id)
    has_one(:tool_ref, Workflow.ToolRefModel, foreign_key: :graphite_tool_id)
    has_one(:leaderboard, Graphite.LeaderboardModel, foreign_key: :tool_id)

    timestamps()
  end

  @fields ~w(deadline deadline_string)a
  @required_fields @fields

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def changeset(tool, params, nil) do
    tool
    |> prepare_deadline_string()
    |> cast(params, @fields)
    |> apply_deadline_change()
  end

  def changeset(tool, params, timezone) do
    tool
    |> prepare_deadline_string(timezone)
    |> cast(params, @fields)
    |> apply_deadline_change(timezone)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  defp prepare_deadline_string(_, timezone \\ "Etc/UTC")

  defp prepare_deadline_string(%{deadline: nil} = tool, _timezone) do
    %{tool | deadline_string: nil}
  end

  defp prepare_deadline_string(%{deadline: deadline} = tool, timezone) do
    deadline_string =
      deadline
      |> Timestamp.convert(timezone)
      |> Timestamp.format_user_input_datetime()

    %{tool | deadline_string: deadline_string}
  end

  defp apply_deadline_change(changeset, timezone \\ "Etc/UTC") do
    if deadline_string = get_change(changeset, :deadline_string) do
      value =
        deadline_string
        |> Timestamp.parse_user_input_datetime(timezone)
        |> Timestamp.convert()

      put_change(changeset, :deadline, value)
    else
      changeset
    end
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :leaderboard,
        :submissions,
        :auth_node
      ])

  def preload_graph(:auth_node), do: [auth_node: []]

  def preload_graph(:submissions),
    do: [submissions: Graphite.SubmissionModel.preload_graph(:down)]

  def preload_graph(:leaderboard),
    do: [leaderboard: Graphite.LeaderboardModel.preload_graph(:down)]

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?()
  end

  def open_for_submissions?(%{deadline: deadline}) when not is_nil(deadline) do
    Timestamp.future?(deadline)
  end

  def open_for_submissions?(_), do: true

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(tool), do: tool.auth_node_id
  end

  defimpl Frameworks.Concept.ToolModel do
    alias Systems.Graphite
    def key(_), do: :graphite
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: ""
    def open_label(_), do: ""
    def ready?(_), do: true
    def form(_, _), do: Graphite.ToolForm

    def launcher(tool) do
      %{
        module: Graphite.ToolView,
        params: %{
          tool: tool
        }
      }
    end

    def task_labels(_) do
      %{
        pending: dgettext("eyra-graphite", "pending.label"),
        participated: dgettext("eyra-graphite", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: false
  end
end
