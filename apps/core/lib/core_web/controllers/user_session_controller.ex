defmodule CoreWeb.UserSessionController do
  use CoreWeb, :controller

  alias Core.Accounts
  alias CoreWeb.UserAuth
  import CoreWeb.Gettext

  plug(
    :setup_sign_in_with_apple,
    Application.fetch_env!(:core, SignInWithApple)
    when action != :delete
  )

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      message = dgettext("eyra-user", "Invalid email or password")
      render(conn |> put_flash(:error, message), "new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp setup_sign_in_with_apple(conn, conf) do
    SignInWithApple.Helpers.setup_session(conn, conf)
  end
end
