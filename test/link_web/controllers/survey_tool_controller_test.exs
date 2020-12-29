defmodule LinkWeb.SurveyToolControllerTest do
  use LinkWeb.ConnCase

  alias Link.Studies
  alias Link.SurveyTools

  @study_attrs %{description: "some description", title: "some title"}
  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  setup %{conn: conn} do
    user = Factories.insert!(:researcher)
    study = Factories.insert!(:study)
    Link.Authorization.assign_role!(user, study, :owner)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user, study: study}
  end

  describe "index" do
    test "lists all survey_tools", %{conn: conn, study: study} do
      conn = get(conn, Routes.study_survey_tool_path(conn, :index, study))
      assert html_response(conn, 200) =~ "Listing Survey tools"
    end
  end

  describe "new survey_tool" do
    test "renders form", %{conn: conn, study: study} do
      conn = get(conn, Routes.study_survey_tool_path(conn, :new, study))
      assert html_response(conn, 200) =~ "New Survey tool"
    end
  end

  describe "create survey_tool" do
    test "redirects to show when data is valid", %{conn: conn, study: study} do
      create_conn =
        post(conn, Routes.study_survey_tool_path(conn, :create, study), survey_tool: @create_attrs)

      assert %{id: id} = redirected_params(create_conn)
      assert redirected_to(create_conn) == Routes.study_survey_tool_path(conn, :show, study, id)

      conn = get(conn, Routes.study_survey_tool_path(conn, :show, study, id))
      assert html_response(conn, 200) =~ "Show Survey tool"
    end

    test "renders errors when data is invalid", %{conn: conn, study: study} do
      conn =
        post(conn, Routes.study_survey_tool_path(conn, :create, study),
          survey_tool: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Survey tool"
    end
  end

  describe "edit survey_tool" do
    setup [:create_survey_tool]

    test "renders form for editing chosen survey_tool", %{
      conn: conn,
      study: study,
      survey_tool: survey_tool
    } do
      conn = get(conn, Routes.study_survey_tool_path(conn, :edit, study, survey_tool))
      assert html_response(conn, 200) =~ "Edit Survey tool"
    end
  end

  describe "update survey_tool" do
    setup [:create_survey_tool]

    test "redirects when data is valid", %{conn: conn, survey_tool: survey_tool, study: study} do
      update_conn =
        put(conn, Routes.study_survey_tool_path(conn, :update, study, survey_tool),
          survey_tool: @update_attrs
        )

      assert redirected_to(update_conn) ==
               Routes.study_survey_tool_path(conn, :show, study, survey_tool)

      conn = get(conn, Routes.study_survey_tool_path(conn, :show, study, survey_tool))
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      study: study,
      survey_tool: survey_tool
    } do
      conn =
        put(conn, Routes.study_survey_tool_path(conn, :update, study, survey_tool),
          survey_tool: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Survey tool"
    end
  end

  describe "delete survey_tool" do
    setup [:create_survey_tool]

    test "deletes chosen survey_tool", %{conn: conn, study: study, survey_tool: survey_tool} do
      delete_conn = delete(conn, Routes.study_survey_tool_path(conn, :delete, study, survey_tool))
      assert redirected_to(delete_conn) == Routes.study_survey_tool_path(conn, :index, study)

      assert_error_sent 404, fn ->
        get(conn, Routes.study_survey_tool_path(conn, :show, study, survey_tool))
      end
    end
  end

  defp create_survey_tool(%{user: user}) do
    {:ok, study} = Studies.create_study(@study_attrs, user)
    {:ok, survey_tool} = SurveyTools.create_survey_tool(@create_attrs, study)
    %{survey_tool: survey_tool, study: study}
  end
end
