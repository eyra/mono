defmodule Core.Repo.Migrations.AddTotalAmountToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :total_amount, :integer, default: 0, null: false
    end
  end
end
