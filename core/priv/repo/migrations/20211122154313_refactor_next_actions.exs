defmodule Core.Repo.Migrations.RefactorNextActions do
  use Ecto.Migration

  def up do
    drop(index(:next_actions, [:user_id, :action]))
    drop(index(:next_actions, [:user_id, :content_node_id, :action]))

    alter table(:next_actions) do
      remove(:content_node_id)
      add(:key, :string, null: true)
    end

    create(unique_index(:next_actions, [:user_id, :action], where: "key is NULL"))
    create(unique_index(:next_actions, [:user_id, :action, :key], where: "key is not NULL"))
  end

  def down do
    drop(index(:next_actions, [:user_id, :action]))
    drop(index(:next_actions, [:user_id, :action, :key]))

    alter table(:next_actions) do
      add(:content_node_id, references(:content_nodes), null: true)
      remove(:key)
    end

    create(unique_index(:next_actions, [:user_id, :action], where: "content_node_id is NULL"))

    create(
      unique_index(:next_actions, [:user_id, :content_node_id, :action],
        where: "content_node_id is not NULL"
      )
    )
  end
end
