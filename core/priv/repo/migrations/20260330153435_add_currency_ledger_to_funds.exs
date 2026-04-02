defmodule Core.Repo.Migrations.AddCurrencyLedgerToFunds do
  use Ecto.Migration

  def change do
    alter table(:funds) do
      add :currency_ledger_id, references(:currency_ledger), null: true
      modify :currency_id, :bigint, null: true, from: {:bigint, null: false}
    end
  end
end
