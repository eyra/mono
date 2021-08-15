defmodule Core.Repo.Migrations.AddCoordinatorRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:coordinator, :boolean)
    end

    create(index(:users, [:coordinator], comment: "Fast lookup of coordinators"))
  end
end
