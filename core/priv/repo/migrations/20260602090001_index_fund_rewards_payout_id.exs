defmodule Core.Repo.Migrations.IndexFundRewardsPayoutId do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    create_if_not_exists(index(:fund_rewards, [:payout_id], concurrently: true))
  end

  def down do
    drop_if_exists(index(:fund_rewards, [:payout_id], concurrently: true))
  end
end
