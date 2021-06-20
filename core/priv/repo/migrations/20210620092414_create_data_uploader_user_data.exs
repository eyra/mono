defmodule Core.Repo.Migrations.CreateDataUploaderUserData do
  use Ecto.Migration

  def change do
    create table(:data_uploader_user_data) do
      add :data, :binary
      add :client_script_id, references(:client_scripts, on_delete: :nothing)

      timestamps()
    end

    create index(:data_uploader_user_data, [:client_script_id])
  end
end
