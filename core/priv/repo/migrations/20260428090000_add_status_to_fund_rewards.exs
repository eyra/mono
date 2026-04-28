defmodule Core.Repo.Migrations.AddStatusToFundRewards do
  use Ecto.Migration

  def up do
    alter table(:fund_rewards) do
      add(:status, :string)
    end

    execute("""
    UPDATE fund_rewards
    SET status = CASE
      WHEN payment_id IS NOT NULL THEN 'paid'
      ELSE 'approved'
    END
    """)

    alter table(:fund_rewards) do
      modify(:status, :string, null: false, default: "reserved")
    end

    create(index(:fund_rewards, [:status]))
  end

  def down do
    drop_if_exists(index(:fund_rewards, [:status]))

    alter table(:fund_rewards) do
      remove(:status)
    end
  end
end
