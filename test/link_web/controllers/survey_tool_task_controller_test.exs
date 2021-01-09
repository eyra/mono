defmodule LinkWeb.SurveyToolTaskControllerTest do
  use LinkWeb.ConnCase
  alias Link.SurveyTools

  setup %{conn: conn} do
    participation =
      %{user: user, study: study} = Factories.insert!(:study_participant, status: :entered)

    survey_tool =
      Factories.insert!(:survey_tool,
        study: study,
        survey_url: "https://#{Faker.Internet.domain_name()}/survey"
      )

    Link.Authorization.assign_role!(user, study, :participant)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)
    {:ok, conn: conn, survey_tool: survey_tool, user: user, participation: participation}
  end

  describe "start" do
    test "show error when a user has no task", %{
      conn: conn,
      survey_tool: survey_tool
    } do
      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
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
      survey_tool: survey_tool,
      participation: participation
    } do
      [task] = SurveyTools.setup_tasks_for_participants!([participation], survey_tool)
      SurveyTools.complete_task!(task)

      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
            conn,
            :start,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "task has already been completed"
    end

    test "show link to the survey when task is available", %{
      conn: conn,
      survey_tool: survey_tool,
      participation: participation
    } do
      SurveyTools.setup_tasks_for_participants!([participation], survey_tool)

      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
            conn,
            :start,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ survey_tool.survey_url
    end
  end

  describe "complete" do
    test "show error when a user has no task", %{
      conn: conn,
      survey_tool: survey_tool
    } do
      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
            conn,
            :complete,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "no task available for you"
    end

    test "show a message when a user has already completed a task", %{
      conn: conn,
      survey_tool: survey_tool,
      participation: participation
    } do
      [task] = SurveyTools.setup_tasks_for_participants!([participation], survey_tool)
      SurveyTools.complete_task!(task)

      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
            conn,
            :complete,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "task has already been completed"
    end

    test "show that the task is now completed", %{
      conn: conn,
      survey_tool: survey_tool,
      participation: participation
    } do
      SurveyTools.setup_tasks_for_participants!([participation], survey_tool)

      conn =
        get(
          conn,
          Routes.study_survey_tool_task_path(
            conn,
            :complete,
            survey_tool.study,
            survey_tool
          )
        )

      assert html_response(conn, 200) =~ "survey task has been completed"
    end
  end
end
