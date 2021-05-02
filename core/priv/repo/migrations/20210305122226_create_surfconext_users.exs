defmodule Link.Repo.Migrations.CreateSurfconextUsers do
  use Ecto.Migration

  def change do
    create table(:surfconext_users) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:sub, :binary, null: false)
      add(:email, :string)
      add(:family_name, :string)
      add(:given_name, :string)
      add(:preferred_username, :string)
      add(:schac_home_organization, :string)
      timestamps()
    end

    create(unique_index(:surfconext_users, :sub))
  end
end
