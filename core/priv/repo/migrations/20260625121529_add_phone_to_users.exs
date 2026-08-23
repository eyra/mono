defmodule Core.Repo.Migrations.AddPhoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:phone, :string, null: true)
    end
  end
end
