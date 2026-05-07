defmodule Core.Repo.Migrations.RemoveToolIdFromPaperRisImportSession do
  use Ecto.Migration

  def change do
    # Drop the index on tool_id
    drop_if_exists(index(:paper_ris_import_session, [:tool_id]))

    # Remove the foreign key constraint and column
    alter table(:paper_ris_import_session) do
      remove(:tool_id)
    end
  end
end
