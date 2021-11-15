defmodule Core.Repo.Migrations.ImproveExpirationTasks do
  use Ecto.Migration

  def up do
    alter table(:crew_tasks) do
      add(:expire_at, :naive_datetime)
    end

    alter table(:crew_members) do
      add(:expire_at, :naive_datetime)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:expire_at)
    end

    alter table(:crew_members) do
      remove(:expire_at)
    end
  end
end
