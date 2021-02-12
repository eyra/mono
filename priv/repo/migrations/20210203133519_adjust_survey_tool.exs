defmodule Link.Repo.Migrations.AdjustSurveyTool do
  use Ecto.Migration

  def change do
    alter table(:survey_tools) do
      add :description, :text
      add :subject_count, :integer
      add :duration, :string
      add :phone_enabled, :boolean
      add :tablet_enabled, :boolean
      add :desktop_enabled, :boolean
      add :is_published, :boolean
      add :published_at, :naive_datetime
    end
  end
end
