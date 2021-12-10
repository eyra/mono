defmodule Core.Repo.Migrations.MakeTaskRejectable do
  use Ecto.Migration

  def up do
    alter table(:crew_tasks) do
      add(:accepted_at, :naive_datetime)
      add(:rejected_at, :naive_datetime)
      add(:rejected_category, :string)
      add(:rejected_message, :string)
    end
  end

  def down do
    alter table(:crew_tasks) do
      remove(:accepted_at)
      remove(:rejected_at)
      remove(:rejected_category)
      remove(:rejected_message)
    end
  end
end
