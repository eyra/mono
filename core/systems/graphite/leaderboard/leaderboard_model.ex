defmodule Systems.Graphite.LeaderboardModel do
  # FIXME rename to Systems.Graphite.Leaderboard.Model ?

  @moduledoc """
  Data model for the `graphite_leaderboard` table.

  # Fields
  - name: :string, Name of the leaderboard as will be displayed on the platform
  - version: :string, Short text to distinguish it from other leaderboards within
    the same challenge.
  - status: :enum (?)
  - metrics: {:array, :string}, List of metrics that will be tracked for
    leaderboard.
  - visibility: Enum with values
    - public: everybody (including anonymous users) can see team names
    - private: team names are hidden for everybody
    - private_with_date: shows team names after the provided date
  - open_date: :naive_datetime, datetime after which everybody can see team names
    for the scores on the leaderboard.
  - generation_date: :naive_datetime, the day the scores for the leaderboard were
    generated
  - allow_anonymous: :boolean, flag to (dis)allow entries that stay anonymous
    even after a board has been made public.
  - tool_id: connects to `Systems.Graphite.ToolModel`
  - auth_node_id: connects to `Core.Authorization.Node`
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Graphite
  }

  schema "graphite_leaderboards" do
    field(:name, :string)
    field(:version, :string)
    field(:status, Ecto.Enum, values: Graphite.Leaderboard.Status.values())
    field(:metrics, {:array, :string})
    field(:visibility, Ecto.Enum, values: [:public, :private, :private_with_date])
    field(:open_date, :naive_datetime)
    field(:generation_date, :naive_datetime)
    field(:allow_anonymous, :boolean)
    has_many(:scores, Graphite.ScoreModel, foreign_key: :leaderboard_id)
    belongs_to(:tool, Graphite.ToolModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  def auth_tree(%__MODULE__{auth_node: auth_node}), do: auth_node

  @fields ~w(name version status metrics visibility open_date generation_date allow_anonymous tool_id)a
  @required_fields ~w()a

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :scores
      ])

  def preload_graph(:scores) do
    [
      scores: Graphite.ScoreModel.preload_graph(:down),
      auth_node: [:role_assignments]
    ]
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(leaderboard), do: leaderboard.auth_node_id
  end
end
