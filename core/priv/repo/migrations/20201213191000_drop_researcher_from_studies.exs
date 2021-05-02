defmodule Core.Repo.Migrations.DropResearcherFromStudies do
  use Ecto.Migration

  def change do
    alter table(:studies) do
      remove(:researcher_id)
    end
  end
end
