defmodule Core.Repo.Migrations.CreateNextActions do
  use Ecto.Migration

  def change do
    create table(:next_actions, primary_key: false) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:action, :string, null: false)
      add(:content_node_id, references(:content_nodes), null: true)
      add(:count, :integer, default: 1, null: false)
      add(:params, :map)

      timestamps()
    end

    create(unique_index(:next_actions, [:user_id, :action], where: "content_node_id is NULL"))

    create(
      unique_index(:next_actions, [:user_id, :content_node_id, :action],
        where: "content_node_id is not NULL"
      )
    )
  end
end
