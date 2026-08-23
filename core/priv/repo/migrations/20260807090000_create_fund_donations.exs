defmodule Core.Repo.Migrations.CreateFundDonations do
  use Ecto.Migration

  def change do
    create table(:fund_donations) do
      # Restore-stable identity, for the same reason fund_payouts.uid exists: the
      # provider idempotency key derives from this and not from the serial id,
      # which a PITR restore rewinds.
      add(:uid, :uuid, null: false)

      add(:user_id, references(:users, on_delete: :restrict), null: false)
      add(:amount_cents, :integer, null: false)
      add(:currency, :string, null: false, default: "eur")
      add(:status, :string, null: false, default: "pending")

      # The provider's uid for the merchant -> partner charge. Charges have no
      # list endpoint at OPP, so this is the only handle we get on it.
      add(:charge_uid, :string)

      add(:failure_reason, :string, size: 2000)

      timestamps()
    end

    alter table(:fund_rewards) do
      add(:donation_id, references(:fund_donations, on_delete: :nilify_all))
    end

    create(unique_index(:fund_donations, [:uid]))
    create(index(:fund_donations, [:user_id]))
    create(unique_index(:fund_donations, [:charge_uid], where: "charge_uid IS NOT NULL"))
    create(index(:fund_rewards, [:donation_id]))
  end
end
