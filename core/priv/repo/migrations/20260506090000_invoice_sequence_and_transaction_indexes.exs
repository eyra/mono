defmodule Core.Repo.Migrations.InvoiceSequenceAndTransactionIndexes do
  use Ecto.Migration

  def up do
    # Replace count-based invoice number generation with a real DB sequence.
    # Atomic, gap-free across deletes, environment-stable.
    execute("CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START WITH 128")

    # Advance the sequence past any invoice IDs already issued by the previous
    # count-based scheme (count + 128). Without this, fresh nextval calls collide
    # with existing rows on environments that already have transactions.
    execute("""
    SELECT setval(
      'invoice_number_seq',
      GREATEST(128, (SELECT COUNT(*) + 128 FROM transactions)),
      false
    )
    """)

    create unique_index(:transactions, [:invoice_id])
    create unique_index(:transactions, [:transaction_id])
  end

  def down do
    drop_if_exists(unique_index(:transactions, [:transaction_id]))
    drop_if_exists(unique_index(:transactions, [:invoice_id]))
    execute("DROP SEQUENCE IF EXISTS invoice_number_seq")
  end
end
