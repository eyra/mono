defmodule Core.Repo.Migrations.RefactorStorageJobData do
  use Ecto.Migration

  def change do
    # Rename table from storage_pending_blobs to storage_job_data
    rename(table(:storage_pending_blobs), to: table(:storage_job_data))

    # Add status field with default "pending"
    alter table(:storage_job_data) do
      add(:status, :string, default: "pending", null: false)
    end

    # Create index for cleanup queries (status + inserted_at)
    create(index(:storage_job_data, [:status, :inserted_at]))
  end
end
