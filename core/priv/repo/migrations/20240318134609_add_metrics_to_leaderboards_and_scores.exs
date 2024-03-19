defmodule Core.Repo.Migrations.AddMetricsToLeaderboardsAndScores do
  use Ecto.Migration

  def up do
    alter table(:graphite_leaderboards) do
      add(:metrics, {:array, :string}, null: false)
    end

    alter table(:graphite_scores) do
      add(:metric, :string, null: false)
    end
  end

  def down do
    alter table(:graphite_scores) do
      remove(:metric)
    end

    alter table(:graphite_leaderboards) do
      remove(:metrics)
    end
  end
end
