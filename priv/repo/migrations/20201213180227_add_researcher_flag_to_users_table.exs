defmodule Link.Repo.Migrations.AddResearcherFlagToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add :researcher, :boolean
    end
  end
end
