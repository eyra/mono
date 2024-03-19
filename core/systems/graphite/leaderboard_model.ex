defmodule Systems.Graphite.LeaderboardModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Graphite
  }

  schema "graphite_leaderboards" do
    field(:name, :string)
    field(:version, :string)
    field(:metrics, {:array, :string})
    has_many(:scores, Graphite.ScoreModel, foreign_key: :leaderboard_id)

    timestamps()
  end

  @fields ~w(name version)a
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

  def preload_graph(:scores), do: [scores: Graphite.ScoreModel.preload_graph(:down)]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(leaderboard), do: leaderboard.auth_node_id
  end
end
