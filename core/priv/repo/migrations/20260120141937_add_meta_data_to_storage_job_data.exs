defmodule Core.Repo.Migrations.AddMetaDataToStorageJobData do
  use Ecto.Migration

  def change do
    alter table(:storage_job_data) do
      add(:meta_data, :map)
    end
  end
end
