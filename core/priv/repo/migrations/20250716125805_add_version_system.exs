defmodule Core.Repo.Migrations.AddVersionSystem do
  use Ecto.Migration

  def change do
    create table(:version) do
      add(:number, :integer)
      add(:parent_id, references(:version))
      timestamps()
    end

    create(index(:version, [:parent_id]))

    create table(:paper_set) do
      add(:category, :string)
      add(:identifier, :integer)
      timestamps()
    end

    create(index(:paper_set, [:category, :identifier], unique: true))
    create(index(:paper_set, [:category]))

    create table(:paper_set_assoc) do
      add(:paper_id, references(:paper))
      add(:set_id, references(:paper_set))
      timestamps()
    end

    create(index(:paper_set_assoc, [:paper_id, :set_id], unique: true))
    create(index(:paper_set_assoc, [:set_id]))

    alter table(:paper) do
      add(:version_id, references(:version))
    end
  end
end
