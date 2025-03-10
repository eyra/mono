defmodule Core.Repo.Migrations.AddManualSystem do
  use Ecto.Migration

  def change do
    # Create manuals table
    create table(:manuals) do
      add(:identifier, :string, null: false)
      add(:title, :string, null: false)
      add(:description, :text)
      add(:userflow_id, references(:userflows, on_delete: :nilify_all))

      timestamps()
    end

    create(unique_index(:manuals, [:identifier]))

    # Create manual_chapters table
    create table(:manual_chapters) do
      add(:identifier, :string, null: false)
      add(:title, :string, null: false)
      add(:description, :text)
      add(:order, :integer, null: false)
      add(:manual_id, references(:manuals, on_delete: :delete_all), null: false)
      add(:userflow_id, references(:userflows, on_delete: :nilify_all))

      timestamps()
    end

    create(unique_index(:manual_chapters, [:identifier, :manual_id]))
    create(unique_index(:manual_chapters, [:order, :manual_id]))
    create(index(:manual_chapters, [:manual_id]))
    create(index(:manual_chapters, [:userflow_id]))
  end
end
