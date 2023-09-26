defmodule Core.Repo.Migrations.RenameSurvey do
  use Ecto.Migration

  def up do
    rename(table(:survey_tools), :survey_url, to: :questionnaire_url)
    rename(table(:survey_tools), to: table(:questionnaire_tools))

    rename(table(:experiments), :survey_tool_id, to: :questionnaire_tool_id)

    rename(table(:tool_refs), :survey_tool_id, to: :questionnaire_tool_id)
    rename(table(:data_donation_tasks), :survey_task_id, to: :questionnaire_task_id)
    rename(table(:data_donation_survey_tasks), to: table(:data_donation_questionnaire_tasks))
  end

  def down do
    rename(table(:data_donation_tasks), :questionnaire_task_id, to: :survey_task_id)
    rename(table(:data_donation_questionnaire_tasks), to: table(:data_donation_survey_tasks))
    rename(table(:tool_refs), :questionnaire_tool_id, to: :survey_tool_id)

    rename(table(:experiments), :questionnaire_tool_id, to: :survey_tool_id)

    rename(table(:questionnaire_tools), to: table(:survey_tools))
    rename(table(:survey_tools), :questionnaire_url, to: :survey_url)
  end
end
