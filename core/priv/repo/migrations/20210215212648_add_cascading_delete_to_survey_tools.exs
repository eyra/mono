defmodule Core.Repo.Migrations.AddCascadingDeleteToSurveyTools do
  use Ecto.Migration

  def up do
    drop(constraint(:survey_tools, "survey_tools_study_id_fkey"))

    alter table(:survey_tools) do
      modify(:study_id, references(:studies, on_delete: :delete_all))
    end
  end
end
