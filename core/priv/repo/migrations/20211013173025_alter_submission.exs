defmodule Core.Repo.Migrations.AlterSubmission do
  use Ecto.Migration

  def up do
    alter table(:pool_submissions) do
      add(:reward_value, :integer)
      add(:reward_currency, :string)
      add(:schedule_start, :string)
      add(:schedule_end, :string)
    end

    create(
      constraint(:pool_submissions, :reward_value_can_not_be_negative,
        check: "reward_value >= 0",
        comment: "A reward can not be negative"
      )
    )
  end

  def down do
    drop constraint(:pool_submissions, :reward_value_can_not_be_negative)

    alter table(:pool_submissions) do
      remove(:reward_value)
      remove(:reward_currency)
      remove(:schedule_start)
      remove(:schedule_end)
    end
  end
end
