defmodule Core.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcement) do
      add(:kind, :string, null: false)
      add(:title, :string, null: false)
      add(:summary, :text, null: false)
      add(:body, :text, null: false)
      add(:priority, :string, null: false, default: "normal")
      add(:published_at, :utc_datetime)
      add(:author_id, references(:users, on_delete: :nilify_all))

      timestamps()
    end

    create(constraint(:announcement, :kind_must_be_valid, check: "kind IN ('release_notes')"))

    create(
      constraint(:announcement, :priority_must_be_valid, check: "priority IN ('normal', 'high')")
    )

    create table(:announcement_recipient) do
      add(:announcement_id, references(:announcement, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:read_at, :utc_datetime)

      timestamps()
    end

    create(unique_index(:announcement_recipient, [:announcement_id, :user_id]))
    create(index(:announcement_recipient, [:user_id]))
  end
end
