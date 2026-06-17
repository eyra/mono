defmodule Core.Repo.Migrations.CreateReconciliationTables do
  use Ecto.Migration

  def change do
    create table(:reconciliation_runs) do
      add(:run_type, :string, null: false, default: "cron")
      add(:started_at, :naive_datetime, null: false)
      add(:finished_at, :naive_datetime)
      add(:scanned, :integer, null: false, default: 0)
      add(:resolved_completed, :integer, null: false, default: 0)
      add(:resolved_failed, :integer, null: false, default: 0)
      add(:still_pending, :integer, null: false, default: 0)
      add(:verified, :integer, null: false, default: 0)
      add(:missing_at_provider, :integer, null: false, default: 0)
      add(:unresolvable, :integer, null: false, default: 0)
      add(:errors, :integer, null: false, default: 0)
      add(:skipped, :integer, null: false, default: 0)
      timestamps()
    end

    create(index(:reconciliation_runs, [:started_at]))

    create table(:reconciliation_findings) do
      add(:reconciliation_run_id, references(:reconciliation_runs, on_delete: :delete_all),
        null: false
      )

      add(:subject_type, :string, null: false)
      add(:subject_id, :integer, null: false)
      add(:provider_uid, :string)
      add(:local_status_before, :string)
      add(:provider_status, :string)
      add(:outcome, :string, null: false)
      add(:details, :map)
      timestamps(updated_at: false)
    end

    create(index(:reconciliation_findings, [:reconciliation_run_id]))
    create(index(:reconciliation_findings, [:outcome]))
    create(index(:reconciliation_findings, [:subject_type, :subject_id]))
  end
end
