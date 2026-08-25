defmodule Core.Repo.Migrations.AddEmailSignUpUser do
  use Ecto.Migration

  def change do
    create table(:email_sign_up_user) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:validation_data, :map)
      add(:validated_at, :naive_datetime)
      timestamps()
    end

    create(unique_index(:email_sign_up_user, :user_id))
  end
end
