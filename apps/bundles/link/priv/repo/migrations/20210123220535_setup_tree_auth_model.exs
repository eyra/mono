defmodule Link.Repo.Migrations.SetupTreeAuthModel do
  use Ecto.Migration

  def change do
    # Create new table for auth-node
    create table(:authorization_nodes) do
      add(:parent_id, references(:authorization_nodes, on_delete: :delete_all))
      timestamps()
    end

    # Create new table for auth-node role assignments
    create table(:authorization_role_assignments) do
      add(:node_id, references(:authorization_nodes, on_delete: :delete_all))
      add(:role, :string)
      add(:principal_id, :bigint)
      timestamps()
    end

    create(
      unique_index(:authorization_role_assignments, [
        :principal_id,
        :role,
        :node_id
      ])
    )
  end
end
