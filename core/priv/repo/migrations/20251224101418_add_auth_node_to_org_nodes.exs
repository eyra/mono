defmodule Core.Repo.Migrations.AddAuthNodeToOrgNodes do
  use Ecto.Migration

  def change do
    alter table(:org_nodes) do
      add(:auth_node_id, references(:authorization_nodes), null: true)
    end
  end
end
