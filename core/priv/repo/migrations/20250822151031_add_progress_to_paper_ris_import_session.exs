defmodule Core.Repo.Migrations.AddProgressToPaperRisImportSession do
  use Ecto.Migration

  def change do
    alter table(:paper_ris_import_session) do
      add(:progress, :map, default: %{})
    end

    rename(table(:paper_ris_import_session), :import_summary, to: :summary)
  end
end
