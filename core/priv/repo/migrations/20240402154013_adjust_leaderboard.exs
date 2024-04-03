defmodule Core.Repo.Migrations.AdjustLeaderboard do
  use Ecto.Migration

  def up do
    alter table(:graphite_leaderboards) do
      add(:status, :string)
      add(:metrics, {:array, :string})
      add(:visibility, :string)
      add(:open_date, :naive_datetime)
      add(:generation_date, :naive_datetime)
      add(:allow_anonymous, :boolean)
      add(:tool_id, references(:graphite_tools))
      add(:auth_node_id, references(:authorization_nodes))
    end

    alter table(:project_items) do
      add(:leaderboard_id, references(:graphite_leaderboards))
    end

    drop(constraint(:project_items, :must_have_at_least_one_reference))

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
    alter table(:graphite_leaderboards) do
      remove(:status)
      remove(:metrics)
      remove(:visibility)
      remove(:open_date)
      remove(:generation_date)
      remove(:allow_anonymous)
      remove(:tool_id)
      remove(:auth_node_id)
    end

    alter table(:project_items) do
      remove(:leaderboard_id)
    end

    # drop(constraint(:project_items, :must_have_at_least_one_reference))

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
