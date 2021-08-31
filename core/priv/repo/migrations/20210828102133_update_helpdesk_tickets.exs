defmodule Core.Repo.Migrations.UpdateHelpdeskTickets do
  use Ecto.Migration

  def change do
    alter table(:helpdesk_tickets) do
      add(:type, :string)
    end
  end
end
