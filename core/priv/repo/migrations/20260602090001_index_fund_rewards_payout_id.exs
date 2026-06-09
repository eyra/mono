defmodule Core.Repo.Migrations.IndexFundRewardsPayoutId do
  use Ecto.Migration

  # fund_rewards is an existing, populated table — build (and drop) the payout_id
  # FK index CONCURRENTLY so a deploy/rollback never takes a write-blocking
  # ACCESS EXCLUSIVE lock on it. Both directions must run outside a transaction.
  @disable_ddl_transaction true
  @disable_migration_lock true

  # Explicit up/down (mirroring 20260428090000) so the rollback also drops
  # CONCURRENTLY — change/0 would auto-reverse to a plain, lock-taking DROP INDEX.
  #
  # up uses create_if_not_exists (not the bare create/1 of the precedent) because
  # environments that ran the original, pre-split create_fund_payouts migration
  # already built this index concurrently; a plain create would error there.
  # Trade-off: a left-over INVALID index from a previously-interrupted concurrent
  # build is skipped rather than rebuilt — reindex it manually if that occurs.
  def up do
    create_if_not_exists(index(:fund_rewards, [:payout_id], concurrently: true))
  end

  def down do
    drop_if_exists(index(:fund_rewards, [:payout_id], concurrently: true))
  end
end
