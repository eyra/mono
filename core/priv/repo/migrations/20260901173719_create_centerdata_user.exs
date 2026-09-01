defmodule Core.Repo.Migrations.CreateCenterdataUser do
  use Ecto.Migration

  def change do
    create table(:centerdata_user) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:sub, :string, null: false)
      add(:email, :string, null: false)
      add(:userinfo, :map, default: %{}, null: false)
      timestamps()
    end

    create(unique_index(:centerdata_user, :sub))
  end
end
