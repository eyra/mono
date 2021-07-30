defmodule Core.Repo.Migrations.AddEdupersonAffiliationToSurfconextUser do
  use Ecto.Migration

  def change do
    alter table(:surfconext_users) do
      add(:eduperson_affiliation, {:array, :string})
    end
  end
end
