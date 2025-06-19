defmodule Core.Repo.Migrations.AddAssignmentInstance do
  use Ecto.Migration

  def up do
    create table(:affiliate) do
      add(:callback_url, :text)
      add(:redirect_url, :text)

      timestamps()
    end

    create table(:affiliate_user) do
      add(:identifier, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:affiliate_id, references(:affiliate, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:affiliate_user, [:affiliate_id]))
    create(index(:affiliate_user, [:user_id]))

    create(
      unique_index(:affiliate_user, [:identifier, :affiliate_id], name: :affiliate_user_unique)
    )

    create table(:affiliate_user_info) do
      add(:info, :text)
      add(:user_id, references(:affiliate_user, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:affiliate_user_info, [:user_id], name: :affiliate_user_info_unique))

    alter table(:assignments) do
      add(:affiliate_id, references(:affiliate, on_delete: :delete_all), null: true)
    end

    create(index(:assignments, [:affiliate_id]))

    create table(:assignment_instance) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:assignment_id, references(:assignments, on_delete: :delete_all))

      timestamps()
    end

    create(index(:assignment_instance, [:user_id]))
    create(index(:assignment_instance, [:assignment_id]))

    create(
      unique_index(:assignment_instance, [:user_id, :assignment_id],
        name: :assignment_instance_unique
      )
    )
  end

  def down do
    drop(table(:assignment_instance))
    drop(table(:affiliate_user))
    drop(table(:affiliate_user_info))
    drop(table(:affiliate))

    alter table(:assignments) do
      remove(:affiliate_id)
    end
  end
end
