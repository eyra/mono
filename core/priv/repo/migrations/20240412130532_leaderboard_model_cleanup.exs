defmodule Core.Repo.Migrations.LeaderboardModelCleanup do
  use Ecto.Migration

  def up do
    rename(table(:graphite_leaderboards), :name, to: :title)
    rename(table(:graphite_leaderboards), :version, to: :subtitle)

    alter table(:graphite_leaderboards) do
      remove(:allow_anonymous)
    end
  end

  def down do
    rename(table(:graphite_leaderboards), :title, to: :name)
    rename(table(:graphite_leaderboards), :subtitle, to: :version)

    alter table(:graphite_leaderboards) do
      add(:allow_anonymous, :boolean)
    end
  end
end
