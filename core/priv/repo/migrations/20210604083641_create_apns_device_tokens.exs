defmodule Core.Repo.Migrations.CreateAPNSDeviceTokens do
  use Ecto.Migration

  def change do
    create table(:apns_device_tokens) do
      add(:device_token, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:apns_device_tokens, [:user_id, :device_token]))
  end
end
