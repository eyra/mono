defmodule Systems.Account.SettingsControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Core.Factories
  alias Systems.Account

  setup :login_as_member

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/user/settings")
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if user is not logged in" do
      conn = CoreWeb.ConnCase.build_conn()
      conn = get(conn, ~p"/user/settings")
      assert redirected_to(conn) == ~p"/user/signin"
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
        put(conn, ~p"/user/settings", %{
          "action" => "update_password",
          "current_password" => password,
          "user" => %{
            "password" => password,
            "password_confirmation" => password
          }
        })

      assert redirected_to(new_password_conn) ==
               ~p"/user/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated"

      assert Account.Public.get_user_by_email_and_password(user.email, password)
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/user/settings", %{
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

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user, password: password} do
      conn =
        put(conn, ~p"/user/settings", %{
          "action" => "update_email",
          "current_password" => password,
          "user" => %{"email" => Faker.Internet.email()}
        })

      assert redirected_to(conn) == ~p"/user/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "A link to confirm your email"
      assert Account.Public.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/user/settings", %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /users/settings/confirm-email/:token" do
    setup %{user: user} do
      email = Faker.Internet.email()

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_update_email_instructions(
            %{user | email: email},
            user.email,
            url
          )
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/user/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/user/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Email address changed"
      refute Account.Public.get_user_by_email(user.email)
      assert Account.Public.get_user_by_email(email)

      conn = get(conn, ~p"/user/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/user/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/user/settings/confirm-email/oops")
      assert redirected_to(conn) == ~p"/user/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Account.Public.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = CoreWeb.ConnCase.build_conn()
      conn = get(conn, ~p"/user/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/user/signin"
    end
  end
end
