defmodule Core.Repo.Migrations.AddLeaderboardToItemModel do
  use Ecto.Migration

  def up do
    drop constraint(:project_items, :must_have_at_least_one_reference)

    alter table(:project_items) do
      add(:leaderboard_id, references(:graphite_leaderboards))
    end

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        tool_ref_id != null or
        assignment_id != null or
        leaderboard_id != null
        """
      )
    )

  end

  def down do
    drop constraint(:project_items, :must_have_at_least_one_reference)

    alter table(:project_items) do
      remove(:leaderboard_id)
    end

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        tool_ref_id != null or
        assignment_id != null
        """
      )
    )
  end
end
