defmodule Core.Repo.Migrations.AddPrerequisitesToPromotions do
  use Ecto.Migration

  def change do
    alter table(:promotions) do
      add :prerequisites, :text
    end
  end
end
