defmodule Core.Repo.Migrations.AddSystemUser do
  use Ecto.Migration

  def up do
    create table(:system_users) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:name, :string, null: false)

      timestamps()
    end

    create(unique_index(:system_users, [:name]))
  end

  def down do
    drop(index(:system_users, [:name]))
    drop(table(:system_users))
  end
end
