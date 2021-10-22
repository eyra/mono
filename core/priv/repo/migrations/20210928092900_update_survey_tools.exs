defmodule Core.Repo.Migrations.UpdateSurveyTools do
  use Ecto.Migration

  def up do
    alter table(:survey_tools) do
      add(:language, :string)
      add(:ethical_approval, :boolean)
    end
  end

  def down do
    alter table(:survey_tools) do
      remove(:language)
      remove(:ethical_approval)
    end
  end
end
