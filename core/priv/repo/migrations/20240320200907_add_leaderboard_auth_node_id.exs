defmodule Core.Repo.Migrations.AddLeaderboardAuthNodeId do
  use Ecto.Migration

  def up do
    alter table(:graphite_leaderboards) do
      add(:auth_node_id, references(:authorization_nodes))
    end
  end

  def down do
    alter table(:graphite_leaderboard) do
      remove(:auth_node_id)
    end
  end
end
