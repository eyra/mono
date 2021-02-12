defmodule Link.Repo.Migrations.AddAuthor do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :fullname, :string
      add :displayname, :string

      add :study_id, references(:studies, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: true

      timestamps()
    end
  end
end
