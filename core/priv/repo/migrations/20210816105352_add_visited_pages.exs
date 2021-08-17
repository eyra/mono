defmodule Core.Repo.Migrations.AddVisitedPages do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:visited_pages, {:array, :string})
    end
  end
end
