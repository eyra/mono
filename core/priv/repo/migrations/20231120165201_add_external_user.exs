defmodule Core.Repo.Migrations.AddExternalUser do
  use Ecto.Migration

  def up do
    create table(:external_users) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:organisation, :string)
      add(:external_id, :string)

      timestamps()
    end

    create(unique_index(:external_users, [:organisation, :external_id]))
  end

  def down do
    drop(index(:external_users, [:organisation, :external_id]))
    drop(table(:external_users))
  end
end
