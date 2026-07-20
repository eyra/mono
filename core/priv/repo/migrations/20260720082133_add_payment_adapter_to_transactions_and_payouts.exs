defmodule Core.Repo.Migrations.AddPaymentAdapterToTransactionsAndPayouts do
  use Ecto.Migration

  # Records which payment adapter realized each transaction/payout ("opp" or
  # "local"), set at creation, so reconciliation can skip local-only records
  # instead of guessing from the "free_" id prefix.
  def up do
    # Default "opp" (NOT NULL) so existing rows — and any created by old app
    # instances still live during a rolling deploy, before the new code sets the
    # adapter — satisfy the constraint. Only local-only rows deviate.
    alter table(:transactions) do
      add(:payment_adapter, :string, null: false, default: "opp")
    end

    alter table(:fund_payouts) do
      add(:payment_adapter, :string, null: false, default: "opp")
    end

    flush()

    # Legacy free pay-ins were local-only, not OPP.
    execute(
      "UPDATE transactions SET payment_adapter = 'local' WHERE transaction_id LIKE 'free_%'"
    )
  end

  def down do
    alter table(:transactions) do
      remove(:payment_adapter)
    end

    alter table(:fund_payouts) do
      remove(:payment_adapter)
    end
  end
end
