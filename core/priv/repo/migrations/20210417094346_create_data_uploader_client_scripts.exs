defmodule Core.Repo.Migrations.CreateDataUploaderClientScripts do
  use Ecto.Migration

  def change do
    create table(:client_scripts) do
      add(:title, :string)
      add(:script, :text)
      add(:study_id, references(:studies, on_delete: :nothing))
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create(index(:client_scripts, [:study_id]))
  end
end
