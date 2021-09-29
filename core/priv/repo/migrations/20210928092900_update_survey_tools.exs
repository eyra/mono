defmodule Core.Repo.Migrations.UpdateSurveyTools do
  use Ecto.Migration

  def up do
    alter table(:survey_tools) do
      add(:language, :string)
      add(:rerb_code, :string)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:language)
      remove(:rerb_code)
    end
  end
end
