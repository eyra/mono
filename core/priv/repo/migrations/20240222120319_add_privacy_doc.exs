defmodule Core.Repo.Migrations.AddPrivacyDoc do
  use Ecto.Migration

  def up do
    create table(:content_files) do
      add(:name, :string)
      add(:ref, :string)
      timestamps()
    end

    alter table(:assignments) do
      add(:privacy_doc_id, references(:content_files, on_delete: :nothing))
    end
  end

  def down do
    alter table(:assignments) do
      remove(:privacy_doc_id)
    end

    drop(table(:content_files))
  end
end
