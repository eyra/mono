defmodule Core.Repo.Migrations.GoogleSignIn do
  use Ecto.Migration

  def change do
    create table(:google_sign_in_users) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:sub, :binary, null: false)
      add(:name, :string)
      add(:email, :string)
      add(:email_verified, :boolean)
      add(:given_name, :string)
      add(:family_name, :string)
      add(:picture, :string)
      add(:locale, :string)
      timestamps()
    end

    create(unique_index(:google_sign_in_users, :sub))
  end
end
