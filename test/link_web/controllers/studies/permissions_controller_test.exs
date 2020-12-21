defmodule LinkWeb.Studies.PermissionsControllerTest do
  use LinkWeb.ConnCase

  alias Link.{Studies, Factories}

  setup %{conn: conn} do
    user = Factories.get_or_create_researcher()
    study = Factories.create_study(owner: user)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user, study: study}
  end

  describe "add owner" do
    test "can add user as an owner", %{conn: conn, study: study} do
      additional_user = Factories.get_or_create_researcher()

      update_conn =
        post(conn, Routes.study_permissions_path(conn, :create, study),
          email: additional_user.email
        )

      assert redirected_to(update_conn) ==
               Routes.study_permissions_path(update_conn, :show, study)

      conn = get(conn, Routes.study_permissions_path(conn, :show, study))
      assert html_response(conn, 200) =~ additional_user.email
    end

    test "adding an owner keeps the orignal owners", %{conn: conn, study: study, user: user} do
      current_owners = [user, Factories.get_or_create_researcher()]
      Studies.assign_owners(study, current_owners)

      additional_user = Factories.get_or_create_researcher()

      post(conn, Routes.study_permissions_path(conn, :create, study), email: additional_user.email)

      assert Studies.list_owners(study) == current_owners ++ [additional_user]
    end

    test "reports error when adding non-existing user", %{conn: conn, study: study} do
      conn =
        post(conn, Routes.study_permissions_path(conn, :create, study),
          email: Faker.Internet.email()
        )

      assert html_response(conn, 200) =~ "does not exist"
    end
  end

  describe "remove owner" do
    test "can remove an owner from a study", %{conn: conn, study: study, user: user} do
      additional_user = Factories.get_or_create_researcher()
      Studies.assign_owners(study, [additional_user, user])

      update_conn =
        patch(conn, Routes.study_permissions_path(conn, :change, study),
          owners: [additional_user.id |> to_string()]
        )

      assert redirected_to(update_conn) ==
               Routes.study_permissions_path(update_conn, :show, study)

      conn = get(conn, Routes.study_permissions_path(conn, :show, study))
      refute html_response(conn, 200) =~ additional_user.email
    end
  end
end
