defmodule Core.Repo.Migrations.AddTransactionModel do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :transaction_id, :string, null: false
      add :status, :string, null: false
      add :idempotence_key, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :target_fund_id, references(:funds, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:transactions, [:idempotence_key])
    create index(:transactions, [:user_id])
    create index(:transactions, [:target_fund_id])
  end
end
