defmodule Core.Repo.Migrations.AddSagaPhaseToFundPayouts do
  use Ecto.Migration

  def up do
    alter table(:fund_payouts) do
      # Restore-stable identity for the provider idempotency keys. They were
      # derived from the serial id, so a PITR restore (which rewinds sequences)
      # made a later payout reuse an id the provider had already seen — and,
      # since the key is also written as the withdrawal's `reference`, made two
      # distinct payouts share a reference at the provider forever.
      add(:uid, :uuid)

      # The provider's uid for the platform -> participant transfer. Charges have
      # no list endpoint at OPP, so a transfer whose response we failed to persist
      # is otherwise unfindable. This is the only handle we get on it.
      add(:transfer_uid, :string)

      # Set only once the provider has accepted the transfer. Gates the revert
      # path: past this point the money has moved, and releasing the reward lock
      # would let a later payout charge the platform a second time.
      add(:funds_committed_at, :naive_datetime)

      # A withdrawal the provider created and then rejected still owns its
      # idempotency key, so re-issuing one needs a demonstrably fresh key.
      add(:withdrawal_attempt, :integer, null: false, default: 0)
    end

    execute("UPDATE fund_payouts SET uid = gen_random_uuid() WHERE uid IS NULL")

    alter table(:fund_payouts) do
      modify(:uid, :uuid, null: false)
    end

    create(unique_index(:fund_payouts, [:uid]))
    create(unique_index(:fund_payouts, [:transfer_uid], where: "transfer_uid IS NOT NULL"))
  end

  def down do
    drop(unique_index(:fund_payouts, [:transfer_uid], where: "transfer_uid IS NOT NULL"))
    drop(unique_index(:fund_payouts, [:uid]))

    alter table(:fund_payouts) do
      remove(:withdrawal_attempt)
      remove(:funds_committed_at)
      remove(:transfer_uid)
      remove(:uid)
    end
  end
end
