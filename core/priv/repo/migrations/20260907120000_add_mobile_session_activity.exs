defmodule Core.Repo.Migrations.AddMobileSessionActivity do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add(:last_used_at, :naive_datetime)
    end
  end
end
