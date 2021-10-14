defmodule Core.Repo.Migrations.AlterSubmission do
  use Ecto.Migration

  def up do
    alter table(:pool_submissions) do
      add(:reward_value, :integer)
      add(:reward_currency, :string)
      add(:schedule_start, :string)
      add(:schedule_end, :string)
    end
  end

  def down do
    alter table(:pool_submissions) do
      remove(:reward_value)
      remove(:reward_currency)
      remove(:schedule_start)
      remove(:schedule_end)
    end
  end
end
