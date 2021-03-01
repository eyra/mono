defmodule Link.Repo.Migrations.CreateSurveyToolTasks do
  use Ecto.Migration

  def change do
    create table(:survey_tool_tasks) do
      add(:status, :string, null: false)
      # FIXME: Deleting a user would remove all linked state. Therefore it
      # could cause problems when survey data is destroyed. How should this
      # be handled? A possible solution would be to disallow deletion in this
      # case and instead mark the account in some way.
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:survey_tool_id, references(:survey_tools, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:survey_tool_tasks, [:status]))
    create(index(:survey_tool_tasks, [:survey_tool_id]))
    create(unique_index(:survey_tool_tasks, [:user_id, :survey_tool_id]))
  end
end
