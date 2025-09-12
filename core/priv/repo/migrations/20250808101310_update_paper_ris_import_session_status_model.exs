defmodule Core.Repo.Migrations.UpdatePaperRisImportSessionStatusModel do
  use Ecto.Migration

  def up do
    # Add the new phase column
    alter table(:paper_ris_import_session) do
      add(:phase, :string, null: false, default: "waiting")
    end

    # Update existing records to new status values
    execute("""
      UPDATE paper_ris_import_session
      SET status = CASE
        WHEN status IN ('parsing', 'parsed', 'importing') THEN 'activated'
        WHEN status = 'completed' THEN 'succeeded'
        ELSE 'failed'
      END
    """)

    # Update existing records to appropriate phases
    execute("""
      UPDATE paper_ris_import_session
      SET phase = CASE
        WHEN status = 'parsing' THEN 'parsing'
        WHEN status = 'parsed' THEN 'processing'
        WHEN status = 'importing' THEN 'importing'
        ELSE 'waiting'
      END
    """)

    # Remove the started_at column since we use inserted_at instead
    alter table(:paper_ris_import_session) do
      remove(:started_at)
    end

    # Update indexes
    drop_if_exists(index(:paper_ris_import_session, [:status]))
    create(index(:paper_ris_import_session, [:status]))
    create(index(:paper_ris_import_session, [:phase]))
  end

  def down do
    # Restore the started_at column
    alter table(:paper_ris_import_session) do
      add(:started_at, :utc_datetime_usec)
    end

    # Populate started_at with inserted_at for existing records
    execute("UPDATE paper_ris_import_session SET started_at = inserted_at")

    # Make started_at not null
    alter table(:paper_ris_import_session) do
      modify(:started_at, :utc_datetime_usec, null: false)
    end

    # Revert status values to old model
    execute("""
      UPDATE paper_ris_import_session
      SET status = CASE
        WHEN status = 'activated' AND phase = 'waiting' THEN 'parsing'
        WHEN status = 'activated' AND phase = 'parsing' THEN 'parsing'
        WHEN status = 'activated' AND phase = 'processing' THEN 'parsed'
        WHEN status = 'activated' AND phase = 'importing' THEN 'importing'
        WHEN status = 'succeeded' THEN 'completed'
        ELSE 'failed'
      END
    """)

    # Remove the phase column
    alter table(:paper_ris_import_session) do
      remove(:phase)
    end

    # Restore old indexes
    drop_if_exists(index(:paper_ris_import_session, [:status]))
    drop_if_exists(index(:paper_ris_import_session, [:phase]))
    create(index(:paper_ris_import_session, [:status]))
  end
end
