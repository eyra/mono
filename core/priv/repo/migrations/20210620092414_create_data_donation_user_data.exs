defmodule Core.Repo.Migrations.CreateDataDonationUserData do
  use Ecto.Migration

  def change do
    create table(:data_donation_user_data) do
      add(:data, :binary)
      add(:tool_id, references(:data_donation_tools, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:data_donation_user_data, [:tool_id]))
  end
end
