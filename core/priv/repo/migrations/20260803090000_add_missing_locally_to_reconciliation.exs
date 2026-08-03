defmodule Core.Repo.Migrations.AddMissingLocallyToReconciliation do
  use Ecto.Migration

  def change do
    alter table(:reconciliation_runs) do
      add(:missing_locally, :integer, null: false, default: 0)
    end

    # A provider object with no local row has no local id to point at, so the
    # provider→local pass records findings without a subject_id.
    alter table(:reconciliation_findings) do
      modify(:subject_id, :integer, null: true, from: {:integer, null: false})
    end
  end
end
