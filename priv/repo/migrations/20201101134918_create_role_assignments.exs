defmodule Link.Repo.Migrations.CreateRoleAssignments do
  use Ecto.Migration

  def change do
    create table(:role_assignments, primary_key: false) do
      # Expliticly ordered with role last to improve lookup performance.
      add :entity_type, :string
      add :entity_id, :bigint
      add :principal_id, :bigint
      add :role, :string

      timestamps()
    end
  end
end
