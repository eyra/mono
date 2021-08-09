defmodule Core.Repo.Migrations.AddNotificationLog do
  use Ecto.Migration

  def change do
    create table(:notification_center_logs) do
      add(:signal, :string)
      add(:item_type, :string)
      add(:item_id, :integer)
      timestamps()
    end

    create(
      index(:notification_center_logs, [:item_type, :item_id, :signal],
        comment: "Allow fast check for existing log entries"
      )
    )
  end
end
