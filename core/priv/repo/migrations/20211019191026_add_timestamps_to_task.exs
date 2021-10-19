defmodule Core.Repo.Migrations.AddTimestampsToTask do
  use Ecto.Migration

  def up do
    alter table(:crew_tasks) do
      add(:started_at, :naive_datetime)
      add(:completed_at, :naive_datetime)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:started_at)
      remove(:completed_at)
    end
  end
end
