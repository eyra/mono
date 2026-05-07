defmodule Core.Repo.Migrations.DropStorageJobData do
  use Ecto.Migration

  def up do
    drop_if_exists(table(:storage_job_data))
  end

  def down do
    create table(:storage_job_data) do
      add(:data, :binary)
      add(:status, :string, default: "pending")
      add(:meta_data, :map)
      add(:user_id, references(:users, on_delete: :nilify_all))
      timestamps()
    end
  end
end
