defmodule Core.Repo.Migrations.AddPartnerFeeAndLedgerMargin do
  use Ecto.Migration

  def up do
    alter table(:transactions) do
      add(:partner_fee, :integer, null: false, default: 0)
    end

    alter table(:currency_ledger) do
      add(:margin_id, references(:book_accounts), null: true)
    end

    # Every ledger needs a margin account to book the platform fee into; backfill
    # one for each existing ledger, then enforce the invariant.
    execute("""
    DO $$
    DECLARE l RECORD; new_id BIGINT;
    BEGIN
      FOR l IN SELECT id, lower(currency) AS cur FROM currency_ledger WHERE margin_id IS NULL LOOP
        INSERT INTO book_accounts (identifier, balance_debit, balance_credit, inserted_at, updated_at)
          VALUES (ARRAY['ledger', l.cur, 'margin'], 0, 0, now(), now())
          RETURNING id INTO new_id;
        UPDATE currency_ledger SET margin_id = new_id WHERE id = l.id;
      END LOOP;
    END $$;
    """)

    execute("ALTER TABLE currency_ledger ALTER COLUMN margin_id SET NOT NULL")
  end

  def down do
    alter table(:currency_ledger) do
      remove(:margin_id)
    end

    execute(
      "DELETE FROM book_accounts WHERE identifier[1] = 'ledger' AND identifier[3] = 'margin'"
    )

    alter table(:transactions) do
      remove(:partner_fee)
    end
  end
end
