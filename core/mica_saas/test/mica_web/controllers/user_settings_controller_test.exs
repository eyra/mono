defmodule MicaSaas.Systems.Account.SettingsControllerTest do
  use MicaSaasWeb.ConnCase, async: true

  alias Mica.Factories
  alias Systems.Account

  setup :login_as_member

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~m"/user/settings")
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if user is not logged in" do
      conn = MicaSaasWeb.ConnCase.build_conn()
      conn = get(conn, ~m"/user/settings")
      assert redirected_to(conn) == Mica.SaaS.module().sign_in_page()
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{
      conn: conn,
      user: user,
      password: password
    } do
      _new_password = Factories.valid_user_password()

      new_password_conn =
        put(conn, ~m"/user/settings", %{
          "action" => "update_password",
          "current_password" => password,
          "user" => %{
            "password" => password,
            "password_confirmation" => password
          }
        })

      assert redirected_to(new_password_conn) ==
               ~m"/user/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated"

      assert Account.Public.get_user_by_email_and_password(user.email, password)
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~m"/user/settings", %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "no email change on /user/settings" do
    test "the settings page has no email form", %{conn: conn} do
      response = conn |> get(~m"/user/settings") |> html_response(200)
      refute response =~ "update_email"
      refute response =~ "Change email"
    end

    test "an update_email action changes nothing", %{conn: conn, user: user, password: password} do
      assert_error_sent(400, fn ->
        put(conn, ~m"/user/settings", %{
          "action" => "update_email",
          "current_password" => password,
          "user" => %{"email" => Faker.Internet.email()}
        })
      end)

      assert Account.Public.get_user_by_email(user.email)
    end

    test "the email confirmation link is gone", %{conn: conn} do
      assert %{status: 404} = get(conn, "/user/settings/activate-account/any-token")
    end
  end
end
