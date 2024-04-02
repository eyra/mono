defmodule Core.Repo.Migrations.LinkLeaderboardToGraphiteTool do
  use Ecto.Migration

  def up do
    alter table(:graphite_leaderboards) do
      add(:tool_id, references(:graphite_tools))
      add(:status, :string)
      add(:visibility, :string)
      add(:open_date, :naive_datetime)
      add(:generation_date, :naive_datetime)
      add(:allow_anonymous, :boolean)
    end
  end

  def down do
    alter table(:graphite_leaderboards) do
      remove(:tool_id)
      remove(:status)
      remove(:visibility)
      remove(:open_date)
      remove(:generation_date)
      remove(:allow_anonymous)
    end
  end
end
