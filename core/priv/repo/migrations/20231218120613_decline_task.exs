defmodule Core.Repo.Migrations.DeclineTask do
  use Ecto.Migration

  def up do
    alter table(:crew_members) do
      add(:declined_at, :naive_datetime)
      add(:declined, :boolean)
    end

    alter table(:crew_tasks) do
      add(:declined_at, :naive_datetime)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:declined_at)
    end

    alter table(:crew_members) do
      remove(:declined)
      remove(:declined_at)
    end
  end
end
