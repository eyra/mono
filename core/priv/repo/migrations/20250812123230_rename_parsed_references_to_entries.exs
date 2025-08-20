defmodule Core.Repo.Migrations.RenameParsedReferencesToEntries do
  use Ecto.Migration

  def change do
    rename(table(:paper_ris_import_session), :parsed_references, to: :entries)
  end
end
