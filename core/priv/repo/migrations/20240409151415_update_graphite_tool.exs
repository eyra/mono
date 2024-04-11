defmodule Core.Repo.Migrations.UpdateGraphiteTool do
  use Ecto.Migration

  def up do
    alter table(:graphite_tools) do
      add(:deadline, :utc_datetime)
    end
  end

  def down do
    alter table(:graphite_tools) do
      remove(:deadline)
    end
  end
end
