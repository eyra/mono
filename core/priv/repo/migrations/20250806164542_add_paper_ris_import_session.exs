defmodule Core.Repo.Migrations.AddPaperRisImportSession do
  use Ecto.Migration

  def change do
    create table(:paper_ris_import_session) do
      # Foreign keys
      add(:tool_id, references(:zircon_screening_tool, on_delete: :delete_all), null: false)
      add(:paper_set_id, references(:paper_set, on_delete: :delete_all), null: false)

      add(:reference_file_id, references(:paper_reference_file, on_delete: :delete_all),
        null: false
      )

      # Status tracking
      add(:status, :string, null: false, default: "parsing")
      # Status values: parsing, parsed, importing, completed, failed

      # Parsed data storage (JSONB for flexibility)
      add(:parsed_references, :map, default: %{})

      # Structure: [%{status: "new|existing|error", title: "...", authors: [...], year: ..., doi: "...", paper_id: 123, error: "..."}]

      # Import summary
      add(:import_summary, :map, default: %{})
      # Structure: %{total: 0, new: 0, existing: 0, errors: 0, imported: 0}

      # Error tracking
      add(:errors, {:array, :string}, default: [])

      # Timing
      add(:started_at, :utc_datetime_usec, null: false)
      add(:completed_at, :utc_datetime_usec)

      timestamps()
    end

    # Indexes for common queries
    create(index(:paper_ris_import_session, [:tool_id]))
    create(index(:paper_ris_import_session, [:reference_file_id]))
    create(index(:paper_ris_import_session, [:status]))
    create(index(:paper_ris_import_session, [:started_at]))

    # Ensure only one active import per reference file at a time
    create(
      unique_index(:paper_ris_import_session, [:reference_file_id],
        where: "status IN ('parsing', 'parsed', 'importing')",
        name: :paper_ris_import_session_active_unique_index
      )
    )
  end
end
