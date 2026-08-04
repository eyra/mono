defmodule Core.Repo.Migrations.AddApprovedRequiresPaymentCheckToFundRewards do
  use Ecto.Migration

  # Enforce, at the database, the invariant that an :approved reward always has a
  # payment. It is currently guaranteed only by the approval Multi in app code;
  # this CHECK stops any future non-Multi path (raw insert, bulk update, manual
  # SQL) from leaving an approved reward without a payment_id.
  #
  # Added NOT VALID first — a brief ACCESS EXCLUSIVE lock, no table scan — then
  # VALIDATE separately, which only takes a SHARE UPDATE EXCLUSIVE lock and lets
  # reward writes continue while it scans. Non-transactional so the two statements
  # commit independently; a single transaction would hold the ADD's exclusive lock
  # across the whole VALIDATE scan, defeating the point.
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute("""
    ALTER TABLE fund_rewards
      ADD CONSTRAINT approved_requires_payment
      CHECK (status <> 'approved' OR payment_id IS NOT NULL)
      NOT VALID
    """)

    execute("ALTER TABLE fund_rewards VALIDATE CONSTRAINT approved_requires_payment")
  end

  def down do
    execute("ALTER TABLE fund_rewards DROP CONSTRAINT approved_requires_payment")
  end
end
