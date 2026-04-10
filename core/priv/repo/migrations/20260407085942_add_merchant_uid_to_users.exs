defmodule Core.Repo.Migrations.AddMerchantUidToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :merchant_uid, :string, null: true
    end
  end
end
