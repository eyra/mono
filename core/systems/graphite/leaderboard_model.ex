defmodule Systems.Graphite.LeaderboardModel do
  @moduledoc """
  Data model for the `graphite_leaderboard` table.
  # Fields
  - title: :string, Title of the leaderboard as will be displayed on the platform
  - subtitle: :string, Short subtitle for the leaderboard
  - status: :enum (?)
  - metrics: {:array, :string}, List of metrics that will be tracked for
    leaderboard.
  - visibility: Enum with values
    - public: everybody (including anonymous users) can see team names
    - private: team names are hidden for everybody
  - open_date: :naive_datetime, datetime after which everybody can see team names
    for the scores on the leaderboard.
  - generation_date: :naive_datetime, the day the scores for the leaderboard were
    generated
  - tool_id: connects to `Systems.Graphite.ToolModel`
  - auth_node_id: connects to `Core.Authorization.Node`
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  use Gettext, backend: CoreWeb.Gettext
  import Ecto.Changeset

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Concept
  alias Systems.Graphite
  alias Systems.Project

  schema "graphite_leaderboards" do
    field(:title, :string)
    field(:subtitle, :string)
    field(:status, Ecto.Enum, values: Concept.Leaf.Status.values())
    field(:metrics, {:array, :string})
    field(:visibility, Ecto.Enum, values: Graphite.LeaderboardVisibility.values())
    field(:open_date, :naive_datetime)
    field(:generation_date, :naive_datetime)

    has_many(:scores, Graphite.ScoreModel, foreign_key: :leaderboard_id)
    belongs_to(:tool, Graphite.ToolModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:project_item, Project.ItemModel, foreign_key: :leaderboard_id)

    timestamps()
  end

  @fields ~w(title subtitle status metrics visibility open_date generation_date)a
  @required_fields ~w()a

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :auth_node,
        :scores,
        :tool
      ])

  def preload_graph(:scores), do: [scores: Graphite.ScoreModel.preload_graph(:down)]

  def preload_graph(:auth_node), do: [auth_node: [:role_assignments]]

  def preload_graph(:tool), do: [tool: []]

  def auth_tree(%Graphite.LeaderboardModel{auth_node: auth_node}), do: auth_node

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(leaderboard), do: leaderboard.auth_node_id
  end

  defimpl Frameworks.Concept.Leaf do
    use Gettext, backend: CoreWeb.Gettext

    def resource_id(%{id: id}), do: "graphite/leaderboard/#{id}"
    def tag(_), do: dgettext("eyra-graphite", "leaderboard.leaf.tag")

    def info(%{id: _id, tool: tool}, timezone) do
      deadline_str = format_datetime(tool.deadline, timezone)
      nr_submissions = Graphite.Public.get_submission_count(tool)

      submission_info =
        dngettext("eyra-graphite", "1 submission", "* submissions", nr_submissions)

      deadline_info =
        dgettext("eyra-graphite", "leaderboard.deadline.info", deadline: deadline_str)

      [
        [submission_info, deadline_info]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("  |  ")
      ]
    end

    def status(%{status: status}), do: %Concept.Leaf.Status{value: status}

    defp format_datetime(nil, _timezone),
      do: dgettext("eyra-project", "leaderboard.unspecified.deadline.label")

    defp format_datetime(_, nil), do: ""

    defp format_datetime(datetime, timezone) do
      datetime
      |> Timestamp.convert(timezone)
      |> Timestamp.format!()
    end
  end

  def online?(%Graphite.LeaderboardModel{status: status}) do
    status == :online
  end

  def offline?(leaderboard) do
    not online?(leaderboard)
  end
end
