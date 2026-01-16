defmodule Core.Repo.Migrations.RemoveTypeFromOrgNodes do
  use Ecto.Migration

  def change do
    alter table(:org_nodes) do
      remove(:type, :string)
    end
  end
end
