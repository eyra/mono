defmodule Link.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles) do
      add(:fullname, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:user_profiles, [:user_id]))
  end
end
