defmodule Core.Repo.Migrations.CreateHelpdeskTickets do
  use Ecto.Migration

  def change do
    create table(:helpdesk_tickets) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:title, :string, null: false)
      add(:description, :text, null: false)
      add(:completed_at, :timestamptz)

      timestamps()
    end

    create(index(:helpdesk_tickets, [:user_id]))
    create(index(:helpdesk_tickets, [:completed_at]))
  end
end
