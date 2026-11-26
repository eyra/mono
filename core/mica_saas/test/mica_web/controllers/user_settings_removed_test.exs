defmodule MicaSaas.Systems.Account.UserSettingsRemovedTest do
  # /user/settings is gone as a whole: its email change and its password form.
  # A password is set through /user/reset-password.
  use MicaSaasWeb.ConnCase, async: true

  alias Systems.Account

  setup :login_as_member

  test "the settings page answers 404", %{conn: conn} do
    assert %{status: 404} = get(conn, "/user/settings")
  end

  test "a password change sent to the settings page answers 404 and changes nothing",
       %{conn: conn, user: user, password: password} do
    conn =
      put(conn, "/user/settings", %{
        "action" => "update_password",
        "current_password" => password,
        "user" => %{
          "password" => "New-" <> password,
          "password_confirmation" => "New-" <> password
        }
      })

    assert %{status: 404} = conn
    assert Account.Public.get_user_by_email_and_password(user.email, password)
  end

  test "the email confirmation link answers 404", %{conn: conn} do
    assert %{status: 404} = get(conn, "/user/settings/activate-account/any-token")
  end
end
