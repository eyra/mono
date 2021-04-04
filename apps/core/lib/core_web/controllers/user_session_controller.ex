defmodule CoreWeb.UserSessionController do
  use CoreWeb, :controller

  alias Core.Accounts
  alias CoreWeb.UserAuth

  plug(:setup_sign_in_with_apple, :core when action != :delete)

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp setup_sign_in_with_apple(conn, otp_app) do
    conf = Application.fetch_env!(otp_app, SignInWithApple)
    SignInWithApple.Helpers.setup_session(conn, conf)
  end
end
