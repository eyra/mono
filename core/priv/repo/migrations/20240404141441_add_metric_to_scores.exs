defmodule Core.Repo.Migrations.AddMetricToScores do
  use Ecto.Migration

  def up do
    alter table(:graphite_scores) do
      add(:metric, :string)
    end
  end

  def down do
    alter table(:graphite_scores) do
      remove(:metric)
    end
  end
end
