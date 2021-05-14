defmodule Core.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notification_boxes) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:notifications) do
      add(:box_id, references(:notification_boxes), null: false)
      add(:title, :string, null: false)
      add(:action, :string)
      add(:status, :string, null: false)
      timestamps()
    end
  end
end
