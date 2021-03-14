defmodule Core.Repo.Migrations.AddAuthNodeToStudy do
  use Ecto.Migration

  def change do
    alter table(:studies) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
    end
  end
end
