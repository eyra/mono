defmodule Link.Repo.Migrations.AddRoleAssignmentsIndex do
  use Ecto.Migration

  def change do
    create unique_index(:role_assignments, [:principal_id, :entity_type, :entity_id, :role])
  end
end
