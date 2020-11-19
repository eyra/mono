defmodule LinkWeb.StudyControllerTest do
  use LinkWeb.ConnCase

  alias Link.Studies

  @create_attrs %{description: "some description", title: "some title"}
  @update_attrs %{description: "some updated description", title: "some updated title"}
  @invalid_attrs %{description: nil, title: nil}

  setup %{conn: conn} do
    user = user_fixture()
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all studies", %{conn: conn} do
      conn = get(conn, Routes.study_path(conn, :index))
      assert html_response(conn, 200) =~ "Study Overview"
    end
  end

  describe "new study" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.study_path(conn, :new))
      assert html_response(conn, 200) =~ "New Study"
    end
  end

  describe "create study" do
    test "redirects to show when data is valid", %{conn: conn} do
      create_conn = post(conn, Routes.study_path(conn, :create), study: @create_attrs)

      assert %{id: id} = redirected_params(create_conn)
      assert redirected_to(create_conn) == Routes.study_path(create_conn, :show, id)

      conn = get(conn, Routes.study_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Study"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.study_path(conn, :create), study: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Study"
    end
  end

  describe "edit study" do
    setup [:create_study]

    test "renders form for editing chosen study", %{conn: conn, study: study} do
      conn = get(conn, Routes.study_path(conn, :edit, study))
      assert html_response(conn, 200) =~ "Edit Study"
    end

    test "deny editing a non-owned study", %{conn: conn} do
      # Setup a study owned by a different user
      {:ok, study: study} = create_study(%{user: user_fixture()})
      # Now try to load that study
      conn = get(conn, Routes.study_path(conn, :edit, study))
      # The result should be an access denied error
      assert response(conn, 401) =~
               "The current principal does not have permission: invoke/link_web/study_controller@edit"
    end
  end

  describe "update study" do
    setup [:create_study]

    test "redirects when data is valid", %{conn: conn, study: study} do
      update_conn = put(conn, Routes.study_path(conn, :update, study), study: @update_attrs)
      assert redirected_to(update_conn) == Routes.study_path(update_conn, :show, study)

      conn = get(conn, Routes.study_path(conn, :show, study))
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, study: study} do
      conn = put(conn, Routes.study_path(conn, :update, study), study: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Study"
    end
  end

  describe "delete study" do
    setup [:create_study]

    test "deletes chosen study", %{conn: conn, study: study} do
      delete_conn = delete(conn, Routes.study_path(conn, :delete, study))
      assert redirected_to(delete_conn) == Routes.study_path(delete_conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.study_path(conn, :show, study))
      end
    end
  end

  defp create_study(%{user: user}) do
    {:ok, study} = Studies.create_study(@create_attrs, user)
    {:ok, study: study}
  end
end
