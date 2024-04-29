defmodule Core.Repo.Migrations.UpdateGraphiteScoresUniqueIndex do
  use Ecto.Migration

  def up do
    drop(index(:benchmark_scores, [:leaderboard_id, :submission_id]))

    create(
      unique_index(:graphite_scores, [:leaderboard_id, :submission_id, :metric],
        name: :benchmark_scores_leaderboard_id_submission_id_index
      )
    )
  end

  def down do
    drop(index(:graphite_scores, [:leaderboard_id, :submission_id, :metric]))

    create(
      unique_index(:graphite_scores, [:leaderboard_id, :submission_id],
        name: :graphite_scores_leaderboard_id_submission_id_index
      )
    )
  end
end
