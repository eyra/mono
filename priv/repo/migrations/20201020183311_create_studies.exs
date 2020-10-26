defmodule Link.Repo.Migrations.CreateStudies do
  use Ecto.Migration

  def change do
    create table(:studies) do
      add :title, :string
      add :description, :string
      add :researcher_id, references(:users), null: false

      timestamps()
    end
  end
end
