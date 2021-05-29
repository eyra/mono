defmodule Core.Repo.Migrations.CreateWebPushSubscriptions do
  use Ecto.Migration

  def change do
    create table(:web_push_subscriptions) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:endpoint, :string, null: false)
      add(:expiration_time, :integer)
      add(:auth, :string, null: false)
      add(:p256dh, :string, null: false)

      timestamps()
    end

    create(index(:web_push_subscriptions, [:user_id]))
    create(unique_index(:web_push_subscriptions, [:endpoint]))
  end
end
