defmodule Core.Repo.Migrations.AddManualSystem do
  use Ecto.Migration

  def change do
    create table(:userflow) do
      timestamps()
    end

    create table(:userflow_step) do
      add(:order, :integer, null: false)
      add(:group, :string, null: false)
      add(:userflow_id, references(:userflow, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:userflow_step, [:userflow_id, :order]))
    create(index(:userflow_step, [:userflow_id]))
    create(index(:userflow_step, [:group]))

    create table(:userflow_progress) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:step_id, references(:userflow_step, on_delete: :delete_all), null: false)

      timestamps()
    end

    create table(:manual) do
      add(:title, :string)
      add(:description, :text)
      add(:userflow_id, references(:userflow, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:manual, [:userflow_id]))

    create table(:manual_chapter) do
      add(:title, :string)
      add(:description, :text)
      add(:manual_id, references(:manual, on_delete: :delete_all), null: false)
      add(:userflow_step_id, references(:userflow_step, on_delete: :delete_all), null: false)
      add(:userflow_id, references(:userflow, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:manual_chapter, [:manual_id]))
    create(index(:manual_chapter, [:userflow_step_id]))
    create(index(:manual_chapter, [:userflow_id]))

    create table(:manual_page) do
      add(:image, :string)
      add(:title, :string)
      add(:text, :text)
      add(:chapter_id, references(:manual_chapter, on_delete: :delete_all), null: false)
      add(:userflow_step_id, references(:userflow_step, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:manual_page, [:chapter_id]))
    create(index(:manual_page, [:userflow_step_id]))

    # Add unique indexes
    create(unique_index(:userflow_progress, [:user_id, :step_id]))
  end
end
