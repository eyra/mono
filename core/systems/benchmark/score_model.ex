defmodule Systems.Benchmark.ScoreModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Benchmark
  }

  schema "benchmark_scores" do
    field(:score, :float)
    belongs_to(:leaderboard, Benchmark.LeaderboardModel)
    belongs_to(:submission, Benchmark.SubmissionModel)

    timestamps()
  end

  @fields ~w(score)a
  @required_fields ~w()a

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :submission
      ])

  def preload_graph(:submission), do: [submission: Benchmark.SubmissionModel.preload_graph(:down)]
end
