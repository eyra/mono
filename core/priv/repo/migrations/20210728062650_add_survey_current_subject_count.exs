defmodule Core.Repo.Migrations.AddSurveyCurrentSubjectCount do
  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE survey_tools ADD COLUMN current_subject_count integer NOT NULL DEFAULT 0;"
    )

    execute("""


    CREATE OR REPLACE FUNCTION set_survey_tool_current_subject_count()
         RETURNS TRIGGER AS $$
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        UPDATE survey_tools SET
          current_subject_count=(SELECT COUNT(*) FROM survey_tool_participants
                                 WHERE survey_tool_id=OLD.survey_tool_id)
        WHERE survey_tools.id=OLD.survey_tool_id;
      ELSIF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        UPDATE survey_tools SET
          current_subject_count=(SELECT COUNT(*) FROM survey_tool_participants
                                 WHERE survey_tool_id=NEW.survey_tool_id)
        WHERE survey_tools.id=NEW.survey_tool_id;
      END IF;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""

    CREATE TRIGGER survey_tool_current_subject_count
    AFTER INSERT OR UPDATE OR DELETE ON survey_tool_participants
    FOR EACH ROW EXECUTE FUNCTION set_survey_tool_current_subject_count();
    """)
  end

  def down do
    execute("DROP TRIGGER survey_tool_current_subject_count;")
    execute("ALTER TABLE survey_tools DROP COLUMN current_subject_count;")
  end
end
