defmodule Core.Repo.Migrations.CreateAuthCodes do
  use Ecto.Migration

  def change do
    create table(:auth_codes) do
      add(:code_hash, :binary, null: false)
      add(:email, :string, null: false)
      add(:attempts, :integer, null: false, default: 0)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps(updated_at: false)
    end

    create(index(:auth_codes, [:email]))
  end
end
