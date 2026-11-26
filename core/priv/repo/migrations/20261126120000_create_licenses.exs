defmodule Mica.Repo.Migrations.CreateLicenses do
  use Ecto.Migration

  # One row per license support gives: the newest row of a user and license is
  # that license's state. Switching it off fills `revoked_at` and `revoked_by_id`
  # on that row; giving it again adds a row. Rows are never deleted, so who gave
  # or switched off each license, and when, stays.
  #
  # Rolling back drops the table: every license and its history is lost, and
  # migrating up again doesn't bring them back.
  def change do
    create table(:licenses) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:license, :string, null: false)
      add(:valid_until, :date, null: false)
      add(:granted_at, :utc_datetime, null: false)
      add(:granted_by_id, references(:users, on_delete: :nilify_all))
      add(:revoked_at, :utc_datetime)
      add(:revoked_by_id, references(:users, on_delete: :nilify_all))

      timestamps()
    end

    create(index(:licenses, [:user_id, :license, :granted_at]))
  end
end
