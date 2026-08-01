defmodule Core.Repo.Migrations.AddParticipationLifecycle do
  use Ecto.Migration

  def up do
    alter table(:assignment_participation) do
      add(:completed_at, :naive_datetime)
      add(:accepted_at, :naive_datetime)
      add(:rejected_at, :naive_datetime)
      add(:rejected_message, :string)
    end
  end

  def down do
    alter table(:assignment_participation) do
      remove(:rejected_message)
      remove(:rejected_at)
      remove(:accepted_at)
      remove(:completed_at)
    end
  end
end
