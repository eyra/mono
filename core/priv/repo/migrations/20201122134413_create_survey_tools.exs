defmodule Core.Repo.Migrations.CreateTools do
  use Ecto.Migration

  def change do
    create table(:survey_tools) do
      add(:title, :string)
      add(:study_id, references(:studies), null: false)

      timestamps()
    end
  end
end
