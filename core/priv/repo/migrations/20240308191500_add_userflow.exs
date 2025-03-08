defmodule Core.Repo.Migrations.AddUserflow do
  use Ecto.Migration

  def change do
    # Create userflows table
    create table(:userflows) do
      add :identifier, :string, null: false
      add :title, :string, null: false

      timestamps()
    end

    create unique_index(:userflows, [:identifier])

    # Create userflow_steps table
    create table(:userflow_steps) do
      add :identifier, :string, null: false
      add :order, :integer, null: false
      add :group, :string, null: false
      add :userflow_id, references(:userflows, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:userflow_steps, [:identifier, :userflow_id])
    create unique_index(:userflow_steps, [:order, :userflow_id])
    create index(:userflow_steps, [:group])

    # Create userflow_progress table
    create table(:userflow_progress) do
      add :visited_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :step_id, references(:userflow_steps, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:userflow_progress, [:user_id, :step_id])
    create index(:userflow_progress, [:visited_at])
  end
end
