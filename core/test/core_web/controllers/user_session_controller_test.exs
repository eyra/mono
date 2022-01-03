defmodule CoreWeb.UserSessionControllerTest do
  use CoreWeb.ConnCase, async: true
  alias CoreWeb.Router.Helpers, as: Routes

  alias Core.Factories

  defp create_user(_ctx) do
    password = Factories.valid_user_password()
    user = Factories.insert!(:member, %{password: password})
    %{user: user, password: password}
  end

  describe "GET /user/signin" do
    # setup [:create_user]

    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Log in"
    end
  end

  describe "GET /users/signin as member" do
    setup [:login_as_member]

    test "redirects if already logged in", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/dashboard"
    end
  end

  describe "POST /users/signin" do
    setup [:create_user]

    test "logs the user in", %{conn: conn, user: user, password: password} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => password}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ "Eyra Next"
    end

    test "logs the user in with remember me", %{conn: conn, user: user, password: password} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => password,
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_core_web_user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, user: user, password: password} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => password
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /users/signout" do
    setup [:login_as_member]

    test "logs the user out", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/user/signin"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end

  describe "DELETE /users/signout as visitor" do
    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/user/signin"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
