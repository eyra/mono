defmodule Link.Repo.Migrations.MoveParticipantsToSurveyTool do
  use Ecto.Migration

  def change do
    drop(table(:study_participants))

    create table(:survey_tool_participants) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:survey_tool_id, references(:survey_tools, on_delete: :delete_all))

      timestamps()
    end

    # Used to ensure there is only one study application for each user.
    # Also allows quick listing of all users belonging to a survey tool.
    create(unique_index(:survey_tool_participants, [:survey_tool_id, :user_id]))
  end
end
