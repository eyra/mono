defmodule LinkWeb.SurveyToolTaskControllerTest do
  use LinkWeb.ConnCase
  alias Link.SurveyTools

  setup %{conn: conn} do
    user = Factories.insert!(:member)
    survey_tool = Factories.insert!(:survey_tool)
    Link.Authorization.assign_role!(user, survey_tool.study, :participant)
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

      assert response(conn, 401) =~ "not allowed"
    end

    test "show a message when a user has already completed a task", %{
      conn: conn,
      survey_tool: survey_tool,
      user: user
    } do
      SurveyTools.setup_tasks_for_participants(survey_tool)
      SurveyTools.complete_task(survey_tool, user)

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

      assert html_response(conn, 200) =~ "already completed"
    end
  end
end
