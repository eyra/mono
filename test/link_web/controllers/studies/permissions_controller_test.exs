defmodule LinkWeb.Studies.PermissionsControllerTest do
  use LinkWeb.ConnCase

  alias Link.{Studies, Factories, Authorization}

  setup %{conn: conn} do
    user = Factories.insert!(:researcher)
    study = Factories.insert!(:study)
    Authorization.assign_role!(user, study, :owner)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user, study: study}
  end

  describe "add owner" do
    test "can add user as an owner", %{conn: conn, study: study} do
      additional_user = Factories.insert!(:researcher)

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
      current_owners = [user, Factories.insert!(:researcher)]
      Studies.assign_owners(study, current_owners)

      additional_user = Factories.insert!(:researcher)

      post(conn, Routes.study_permissions_path(conn, :create, study), email: additional_user.email)

      assert study |> Studies.list_owners() |> Enum.map(& &1.id) ==
               (current_owners ++ [additional_user]) |> Enum.map(& &1.id)
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
      additional_user = Factories.insert!(:researcher)
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
