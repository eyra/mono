defmodule Core.Repo.Migrations.SimplifySurfconextUserToRawUserinfo do
  use Ecto.Migration

  def change do
    alter table(:surfconext_users) do
      add(:userinfo, :map, default: %{}, null: false)
      remove(:family_name, :string)
      remove(:given_name, :string)
      remove(:preferred_username, :string)
      remove(:schac_home_organization, :string)
      remove(:schac_personal_unique_code, {:array, :string})
      remove(:eduperson_affiliation, {:array, :string})
    end
  end
end
