defmodule Core.Repo.Migrations.AddSurveyToolFlowFields do
  use Ecto.Migration

  def change do
    alter table(:survey_tools) do
      add(:survey_url, :string)
    end
  end
end
