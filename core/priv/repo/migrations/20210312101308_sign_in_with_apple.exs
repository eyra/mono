defmodule Link.Repo.Migrations.SignInWithApple do
  use Ecto.Migration

  def change do
    create table(:sign_in_with_apple_users) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:sub, :binary, null: false)
      add(:email, :string)
      add(:first_name, :string)
      add(:middle_name, :string)
      add(:last_name, :string)
      add(:is_private_email, :boolean)
      timestamps()
    end

    create(unique_index(:sign_in_with_apple_users, :sub))
  end
end
