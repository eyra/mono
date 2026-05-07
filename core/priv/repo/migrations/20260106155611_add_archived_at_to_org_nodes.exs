defmodule Core.Repo.Migrations.AddArchivedAtToOrgNodes do
  use Ecto.Migration

  def change do
    alter table(:org_nodes) do
      add(:archived_at, :utc_datetime, null: true)
    end

    create(index(:org_nodes, [:archived_at]))
  end
end
