defmodule Core.Repo.Migrations.AddStoragePendingBlobs do
  use Ecto.Migration

  def change do
    create table(:storage_pending_blobs) do
      add(:data, :binary, null: false)
      timestamps()
    end

    # Index for cleanup queries (find old blobs)
    create(index(:storage_pending_blobs, [:inserted_at]))
  end
end
