defmodule Core.Repo.Migrations.ImproveNextAction do
  use Ecto.Migration

  def up do
    alter table(:next_actions) do
      add(:content_id, :bigint)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:content_id)
    end
  end
end
