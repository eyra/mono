defmodule Core.Repo.Migrations.AddStatusToFundRewards do
  use Ecto.Migration

  # Non-transactional so the index can build CONCURRENTLY without blocking writes.
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    # Constant-default NOT NULL add is metadata-only on PG11+ (no full-scan lock).
    alter table(:fund_rewards) do
      add(:status, :string, null: false, default: "reserved")
    end

    # Unpaid rewards stay 'reserved' (entry state), not mislabeled 'approved'.
    execute("UPDATE fund_rewards SET status = 'paid' WHERE payment_id IS NOT NULL")

    create(index(:fund_rewards, [:status], concurrently: true))
  end

  def down do
    drop_if_exists(index(:fund_rewards, [:status], concurrently: true))

    alter table(:fund_rewards) do
      remove(:status)
    end
  end
end
