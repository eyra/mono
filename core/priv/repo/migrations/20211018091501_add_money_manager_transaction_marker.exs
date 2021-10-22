defmodule Core.Repo.Migrations.AddMoneyManagerTransactionMarker do
  use Ecto.Migration

  def change do
    create table(:money_manager_transaction_marker) do
      add(:marker, :string, null: false, index: true)
      add(:payment_count, :integer, null: false)
      timestamps()
    end
  end
end
