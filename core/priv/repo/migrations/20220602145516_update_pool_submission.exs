defmodule Core.Repo.Migrations.UpdatePoolSubmission do
  use Ecto.Migration

  def up do
    alter table(:pool_submissions) do
      add(:submitted_at, :naive_datetime)
      add(:accepted_at, :naive_datetime)
      add(:completed_at, :naive_datetime)
    end
  end

  def down do
    alter table(:pool_submissions) do
      remove(:submitted_at)
      remove(:accepted_at)
      remove(:completed_at)
    end
  end
end
