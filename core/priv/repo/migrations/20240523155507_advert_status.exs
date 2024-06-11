defmodule Core.Repo.Migrations.AdvertStatus do
  use Ecto.Migration

  def up do
    alter table(:adverts) do
      add(:status, :string, null: false, default: "concept")
    end
  end

  def down do
    alter table(:adverts) do
      remove(:status)
    end
  end
end
