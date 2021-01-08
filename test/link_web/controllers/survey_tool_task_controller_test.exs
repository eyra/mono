defmodule LinkWeb.SurveyToolTaskControllerTest do
  use LinkWeb.ConnCase
  alias Link.SurveyTools

  setup %{conn: conn} do
    %{user: user, study: study} = Factories.insert!(:study_participant, status: :entered)
    survey_tool = Factories.insert!(:survey_tool, study: study)
    Link.Authorization.assign_role!(user, study, :participant)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)
    {:ok, conn: conn, survey_tool: survey_tool, user: user}
  end

  describe "start" do
    test "show error when a user has no task", %{
      conn: conn,
      survey_tool: survey_tool
    } do
      conn =
        get(
          conn,
          Routes.study_survey_tool_start_task_path(
            conn,
            :start,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "no task available for you"
    end

    test "show a message when a user has already completed a task", %{
      conn: conn,
      survey_tool: survey_tool
    } do
      [task] = SurveyTools.setup_tasks_for_participants!(survey_tool)
      SurveyTools.complete_task!(task)

      conn =
        get(
          conn,
          Routes.study_survey_tool_start_task_path(
            conn,
            :start,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "task has already been completed"
    end
  end
end
