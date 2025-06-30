defmodule Systems.Repo.Migrations.AddActorAuthentication do
  use Ecto.Migration

  def change do
    # Add authentication fields to actor table
    alter table(:actor) do
      add(:description, :text)
      add(:active, :boolean, default: true, null: false)
    end

    # Create actor_tokens table for API authentication
    create table(:actor_tokens) do
      add(:actor_id, references(:actor, on_delete: :delete_all), null: false)
      add(:token, :binary, null: false)
      add(:context, :string, null: false)
      add(:name, :string, null: false)
      add(:expires_at, :naive_datetime)
      add(:last_used_at, :naive_datetime)
      add(:created_by_actor_id, references(:actor, on_delete: :nilify_all))
      timestamps()
    end

    # Create indexes for actor_tokens
    create(index(:actor_tokens, [:actor_id]))
    create(index(:actor_tokens, [:context]))
    create(index(:actor_tokens, [:expires_at]))
    create(unique_index(:actor_tokens, [:token]))

    # Create actor_sessions table for temporary session management
    create table(:actor_sessions) do
      add(:actor_id, references(:actor, on_delete: :delete_all), null: false)
      add(:session_token, :binary, null: false)
      add(:expires_at, :naive_datetime, null: false)
      add(:ip_address, :string)
      add(:user_agent, :text)
      timestamps()
    end

    # Create indexes for actor_sessions
    create(index(:actor_sessions, [:actor_id]))
    create(index(:actor_sessions, [:expires_at]))
    create(unique_index(:actor_sessions, [:session_token]))
  end
end