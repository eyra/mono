defmodule Link.Repo.Migrations.AddCascadingDeleteToAuthors do
  use Ecto.Migration

  def up do
    drop(constraint(:authors, "authors_study_id_fkey"))

    alter table(:authors) do
      modify(:study_id, references(:studies, on_delete: :delete_all))
    end
  end
end
