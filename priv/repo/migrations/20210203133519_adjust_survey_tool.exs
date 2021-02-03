defmodule Link.Repo.Migrations.AdjustSurveyTool do
  use Ecto.Migration

  def change do
    alter table(:survey_tools) do
      add :description, :integer
      add :subject_count, :integer
      add :phone_enabled, :boolean
      add :tablet_enabled, :boolean
      add :desktop_enabled, :boolean
    end
  end
end
