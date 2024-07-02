defmodule Core.Repo.Migrations.AddStorageProjectItem do
  use Ecto.Migration

  def up do
    alter table(:storage_endpoints) do
      add(:auth_node_id, references(:authorization_nodes), null: true)
    end

    alter table(:project_items) do
      add(:storage_endpoint_id, references(:storage_endpoints))
    end

    drop_if_exists(constraint(:project_items, :must_have_at_least_one_reference))

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        assignment_id != null or
        advert_id != null or
        leaderboard_id != null or
        storage_endpoint_id != null
        """
      )
    )
  end

  def down do
    drop_if_exists(constraint(:project_items, :must_have_at_least_one_reference))

    create(
      constraint(:project_items, :must_have_at_least_one_reference,
        check: """
        assignment_id != null or
        advert_id != null or
        leaderboard_id != null
        """
      )
    )

    alter table(:project_items) do
      remove(:storage_endpoint_id)
    end

    alter table(:storage_endpoints) do
      remove(:auth_node_id)
    end
  end
end
