defmodule Systems.Benchmark.LeaderboardModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Benchmark
  }

  schema "benchmark_leaderboards" do
    field(:name, :string)
    field(:version, :string)
    belongs_to(:tool, Benchmark.ToolModel)
    has_many(:scores, Benchmark.ScoreModel, foreign_key: :leaderboard_id)

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

  def preload_graph(:scores), do: [scores: Benchmark.ScoreModel.preload_graph(:down)]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(leaderboard), do: leaderboard.auth_node_id
  end
end
