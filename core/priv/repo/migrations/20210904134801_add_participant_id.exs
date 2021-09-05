defmodule Core.Repo.Migrations.AddParticipantId do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE survey_tools ADD COLUMN next_participant_id BIGINT DEFAULT 0")
    execute("ALTER TABLE survey_tool_participants ADD COLUMN participant_id BIGINT")

    execute("""

    CREATE OR REPLACE FUNCTION set_survey_tool_participants_participant_id()
         RETURNS TRIGGER AS $$
    BEGIN
      UPDATE survey_tools INTO NEW.participant_id
        SET next_participant_id=next_participant_id+1 WHERE survey_tools.id=NEW.survey_tool_id RETURNING next_participant_id;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER survey_tool_participants_participant_id
    BEFORE INSERT ON survey_tool_participants
    FOR EACH ROW EXECUTE FUNCTION set_survey_tool_participants_participant_id();
    """)

    create(unique_index(:survey_tool_participants, [:survey_tool_id, :participant_id]))
  end
end
