defmodule Core.Repo.Migrations.MakeCrewMemberTaskDeletable do
  use Ecto.Migration

  def up do
    alter table(:crew_tasks) do
      add(:expired, :boolean, default: false, null: false)
    end

    alter table(:crew_members) do
      add(:expired, :boolean, default: false, null: false)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:expired)
    end

    alter table(:crew_members) do
      remove(:expired)
    end
  end
end
