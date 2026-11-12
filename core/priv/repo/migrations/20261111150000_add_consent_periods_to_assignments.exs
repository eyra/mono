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
  # Consent is off when every period has ended and the agreement was created no
  # later than the last end, as in `Assignment.Model.consent_periods/1`.
  def down do
    execute("""
    UPDATE assignments SET consent_agreement_id = NULL
    FROM consent_agreements
    WHERE consent_agreements.id = assignments.consent_agreement_id
    AND assignments.consent_periods <> '[]'::jsonb
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(assignments.consent_periods) AS period
      WHERE period->>'ended_at' IS NULL
    )
    AND consent_agreements.inserted_at <= (
      SELECT max((period->>'ended_at')::timestamp)
      FROM jsonb_array_elements(assignments.consent_periods) AS period
    )
    """)

    alter table(:assignments) do
      remove(:consent_periods)
    end
  end
end
