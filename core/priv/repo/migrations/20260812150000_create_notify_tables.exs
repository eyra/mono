defmodule Core.Repo.Migrations.CreateNotifyTables do
  use Ecto.Migration

  def change do
    create table(:notify_event) do
      add(:type, :string, null: false)
      add(:subject_user_id, references(:users, on_delete: :nilify_all), null: false)
      add(:actor_user_id, references(:users, on_delete: :nilify_all))
      add(:metadata, :map, default: %{}, null: false)
      add(:correlation_id, :string)
      add(:source, :string)
      add(:dispatched_at, :utc_datetime_usec)

      timestamps()
    end

    create(index(:notify_event, [:subject_user_id]))
    create(index(:notify_event, [:type]))
    create(index(:notify_event, [:correlation_id]))
    # For the scheduler worker: find pending events cheaply
    create(index(:notify_event, [:dispatched_at]))

    create table(:notify_message) do
      add(:event_id, references(:notify_event, on_delete: :delete_all), null: false)
      add(:channel, :string, null: false)
      add(:payload, :map, default: %{}, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:delivered_at, :utc_datetime_usec)
      add(:seen_at, :utc_datetime_usec)
      add(:failure_reason, :text)
      add(:attempts, :integer, default: 0, null: false)

      timestamps()
    end

    create(index(:notify_message, [:event_id]))
    create(index(:notify_message, [:status, :channel]))
  end
end
