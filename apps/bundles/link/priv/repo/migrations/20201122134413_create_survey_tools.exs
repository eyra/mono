defmodule Link.Repo.Migrations.CreateSurveyTools do
  use Ecto.Migration

  def change do
    create table(:survey_tools) do
      add(:title, :string)
      add(:study_id, references(:studies), null: false)

      timestamps()
    end
  end
end
