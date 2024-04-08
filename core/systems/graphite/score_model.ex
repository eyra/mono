defmodule Systems.Graphite.ScoreModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Graphite
  }

  schema "graphite_scores" do
    field(:score, :float)
    field(:metric, :string)
    belongs_to(:leaderboard, Graphite.LeaderboardModel)
    belongs_to(:submission, Graphite.SubmissionModel)

    timestamps()
  end

  @fields ~w(score metric)a
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

  def preload_graph(:submission), do: [submission: Graphite.SubmissionModel.preload_graph(:down)]
end
