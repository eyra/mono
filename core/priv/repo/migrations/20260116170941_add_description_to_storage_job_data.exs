defmodule Core.Repo.Migrations.AddDescriptionToStorageJobData do
  use Ecto.Migration

  def change do
    alter table(:storage_job_data) do
      add(:description, :string)
    end
  end
end
