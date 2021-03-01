defmodule Link.Repo.Migrations.CreateAccountsAuthTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "")

    drop(table(:user_identities))

    alter table(:user_profiles) do
      remove(:displayname)
      remove(:researcher)
    end

    drop(index(:users, [:email]))

    alter table(:users) do
      modify(:email, :citext, null: false)
      add(:hashed_password, :string)
      add(:confirmed_at, :naive_datetime)
      add(:displayname, :string)
      add(:researcher, :boolean)
    end

    create(unique_index(:users, [:email]))

    create table(:users_tokens) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:token, :binary, null: false)
      add(:context, :string, null: false)
      add(:sent_to, :string)
      timestamps(updated_at: false)
    end

    create(index(:users_tokens, [:user_id]))
    create(unique_index(:users_tokens, [:context, :token]))

    execute("update users set hashed_password='broken'")

    alter table(:users) do
      modify(:hashed_password, :string, null: false)
    end
  end
end
