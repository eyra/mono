defmodule Core.Repo.Migrations.UserVerified do
  use Ecto.Migration

  def up do
    rename(table(:users), :researcher, to: :creator)

    alter table(:users) do
      add(:verified_at, :naive_datetime)
      remove(:student)
      remove(:coordinator)
    end
  end

  def down do
    rename(table(:users), :creator, to: :researcher)

    alter table(:users) do
      remove(:verified_at)
      add(:student, :boolean)
      add(:coordinator, :boolean)
    end
  end
end
