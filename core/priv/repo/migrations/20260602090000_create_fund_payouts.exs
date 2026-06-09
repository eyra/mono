defmodule Core.Repo.Migrations.CreateFundPayouts do
  use Ecto.Migration

  def change do
    create table(:fund_payouts) do
      add(:user_id, references(:users, on_delete: :restrict), null: false)
      add(:amount_cents, :integer, null: false)
      add(:currency, :string, null: false, default: "eur")
      add(:status, :string, null: false, default: "pending")
      add(:provider_uid, :string)
      add(:failure_reason, :string, size: 2000)

      timestamps()
    end

    alter table(:fund_rewards) do
      add(:payout_id, references(:fund_payouts, on_delete: :nilify_all))
    end

    # fund_payouts is brand-new (empty), so plain transactional index builds are
    # safe and instant. CONCURRENTLY would add no benefit here and can't run
    # inside a transaction. The index on the existing fund_rewards table is built
    # CONCURRENTLY in a separate migration so this one stays transactional.
    create(index(:fund_payouts, [:user_id]))

    create(unique_index(:fund_payouts, [:provider_uid], where: "provider_uid IS NOT NULL"))
  end
end
