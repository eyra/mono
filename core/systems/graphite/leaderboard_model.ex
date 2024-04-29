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

  import CoreWeb.Gettext
  import Ecto.Changeset

  alias Systems.{
    Graphite,
    Project
  }

  schema "graphite_leaderboards" do
    field(:title, :string)
    field(:subtitle, :string)
    field(:status, Ecto.Enum, values: Graphite.LeaderboardStatus.values())
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

  def tag(%Graphite.LeaderboardModel{} = _leaderboard) do
    dgettext("eyra-graphite", "tag.leaderboard")
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

  def online?(%Graphite.LeaderboardModel{status: status}) do
    status == :online
  end

  def offline?(leaderboard) do
    not online?(leaderboard)
  end
end
