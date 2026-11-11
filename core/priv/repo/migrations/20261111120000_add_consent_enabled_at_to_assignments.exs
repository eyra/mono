defmodule Mica.Repo.Migrations.AddConsentEnabledAtToAssignments do
  use Ecto.Migration

  def up do
    alter table(:assignments) do
      add(:consent_enabled_at, :naive_datetime)
    end

    flush()

    execute("""
    UPDATE assignments
    SET consent_enabled_at = consent_agreements.inserted_at
    FROM consent_agreements
    WHERE consent_agreements.id = assignments.consent_agreement_id
    """)
  end

  def down do
    execute("UPDATE assignments SET consent_agreement_id = NULL WHERE consent_enabled_at IS NULL")

    alter table(:assignments) do
      remove(:consent_enabled_at)
    end
  end
end
