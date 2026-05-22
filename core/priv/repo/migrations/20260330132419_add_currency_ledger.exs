defmodule Core.Repo.Migrations.AddCurrencyLedger do
  use Ecto.Migration

  def change do
    create table(:currency_ledger) do
      add :currency, :string, null: false
      add :inbound_id, references(:book_accounts), null: false
      add :outbound_id, references(:book_accounts), null: false

      timestamps()
    end

    create unique_index(:currency_ledger, [:currency])
  end
end
