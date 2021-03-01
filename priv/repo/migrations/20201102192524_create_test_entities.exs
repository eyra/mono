defmodule Link.Repo.Migrations.CreateTestEntities do
  use Ecto.Migration

  def change do
    create table(:test_entities) do
      add(:title, :string)

      timestamps()
    end
  end
end
