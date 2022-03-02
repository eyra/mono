defmodule Core.Repo.Migrations.AddAssignmentExclude do
  use Ecto.Migration

  def up do
    create table(:assignment_excludes, primary_key: false) do
      add(:from_id, references(:assignments, on_delete: :delete_all), primary_key: true)
      add(:to_id, references(:assignments, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:assignment_excludes, [:from_id]))
    create(index(:assignment_excludes, [:to_id]))
  end

  def down do
    drop index(:assignment_excludes, [:from_id])
    drop index(:assignment_excludes, [:to_id])

    drop table(:assignment_excludes)
  end
end
