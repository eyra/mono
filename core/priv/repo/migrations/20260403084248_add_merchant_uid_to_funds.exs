defmodule Core.Repo.Migrations.AddMerchantUidToFunds do
  use Ecto.Migration

  def change do
    alter table(:funds) do
      add :merchant_uid, :string, null: true
    end
  end
end
