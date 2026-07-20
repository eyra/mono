defmodule Core.Repo.Migrations.AddPaymentAdapterToTransactionsAndPayouts do
  use Ecto.Migration

  # Records which payment adapter realized each transaction/payout ("opp" or
  # "local"), set at creation, so reconciliation can skip local-only records
  # instead of guessing from the "free_" id prefix.
  def up do
    alter table(:transactions) do
      add(:payment_adapter, :string)
    end

    alter table(:fund_payouts) do
      add(:payment_adapter, :string)
    end

    flush()

    # Legacy rows: free pay-ins were local-only; everything else was OPP.
    execute("""
    UPDATE transactions
    SET payment_adapter = CASE
      WHEN transaction_id LIKE 'free_%' THEN 'local'
      ELSE 'opp'
    END
    """)

    execute("UPDATE fund_payouts SET payment_adapter = 'opp'")

    alter table(:transactions) do
      modify(:payment_adapter, :string, null: false)
    end

    alter table(:fund_payouts) do
      modify(:payment_adapter, :string, null: false)
    end
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
