defmodule Core.Repo.Migrations.ToolRef do
  use Ecto.Migration

  def up do
    alter table(:project_items) do
      remove(:tool_ref_id)
    end

    drop_if_exists(constraint(:project_items, :must_have_at_least_one_reference))

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        assignment_id != null or
        leaderboard_id != null
        """
      )
    )
  end

  def down do
    alter table(:project_items) do
      add(:tool_ref_id, references(:tool_refs, on_delete: :delete_all), null: true)
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
end
