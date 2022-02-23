defmodule Core.Repo.Migrations.UpdateTimeSlot do
  use Ecto.Migration

  def up do
    alter table(:lab_time_slots) do
      add(:enabled?, :boolean, default: true, null: false)
    end
  end

  def down do
    alter table(:lab_time_slots) do
      remove(:enabled?)
    end
  end
end
