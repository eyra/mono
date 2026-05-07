defmodule Core.Repo.Migrations.DropDescriptionFromStorageJobData do
  use Ecto.Migration

  def change do
    alter table(:storage_job_data) do
      remove(:description, :string)
    end
  end
end
