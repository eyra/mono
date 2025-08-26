defmodule Core.Repo.Migrations.AddManualSystem do
  use Ecto.Migration

  def change do
    create table(:userflow) do
      timestamps()
    end

    create table(:userflow_step) do
      add(:order, :integer, null: false)
      add(:group, :string)
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

    create table(:manual_tool) do
      add(:director, :string)
      add(:manual_id, references(:manual, on_delete: :delete_all))
      add(:auth_node_id, references(:authorization_nodes, on_delete: :delete_all))

      timestamps()
    end

    create(index(:manual_tool, [:manual_id]))
    create(index(:manual_tool, [:auth_node_id]))

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      add(:manual_tool_id, references(:manual_tool, on_delete: :delete_all), null: true)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        alliance_tool_id != null or
        feldspar_tool_id != null or
        document_tool_id != null or
        manual_tool_id != null or
        lab_tool_id != null or
        graphite_tool_id != null or
        instruction_tool_id != null or
        zircon_screening_tool_id != null
        """
      )
    )
  end
end
