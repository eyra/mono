defmodule Core.Repo.Migrations.AddRejectionToFundRewards do
  use Ecto.Migration

  def change do
    alter table(:fund_rewards) do
      add(:rejection_reason, :text)
      add(:rejected_at, :naive_datetime)
    end
  end
end
