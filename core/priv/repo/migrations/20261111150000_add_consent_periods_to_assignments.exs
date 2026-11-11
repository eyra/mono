defmodule Mica.Repo.Migrations.AddConsentPeriodsToAssignments do
  use Ecto.Migration

  # No backfill: an assignment without periods and with a linked agreement has had
  # consent on since the agreement was created, which is how older code leaves it.
  def up do
    alter table(:assignments) do
      add(:consent_periods, :jsonb, null: false, default: "[]")
    end
  end

  # Older code reads a linked agreement as consent on, so unlink the agreements of
  # assignments that have consent off. Their texts and signatures stay in place.
  def down do
    execute("""
    UPDATE assignments SET consent_agreement_id = NULL
    WHERE consent_periods <> '[]'::jsonb
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(consent_periods) AS period
      WHERE period->>'ended_at' IS NULL
    )
    """)

    alter table(:assignments) do
      remove(:consent_periods)
    end
  end
end
