defmodule Next.User.SessionController do
  use CoreWeb, :controller
  import CoreWeb.Gettext

  alias Systems.Account

  plug(:setup_sign_in_with_apple, :core when action != :delete)

  defp setup_sign_in_with_apple(conn, otp_app) do
    if feature_enabled?(:signin_with_apple) do
      conf = Application.fetch_env!(otp_app, SignInWithApple)
      SignInWithApple.Helpers.setup_session(conn, conf)
    end
  end

  def new(conn, _params) do
    conn
    |> set_return_to()
    |> render_new()
  end

  defp set_return_to(conn) do
    return_to = Map.get(conn.query_params, "return_to")
    if return_to, do: put_session(conn, :user_return_to, return_to), else: conn
  end

  def create(conn, %{"user" => user_params}) do
    create(conn, user_params)
  end

  def create(conn, %{"email" => email, "password" => password} = user_params) do
    require_feature(:password_sign_in)

    if user = Account.Public.get_user_by_email_and_password(email, password) do
      Account.UserAuth.log_in_user(conn, user, false, user_params)
    else
      message = dgettext("eyra-user", "Invalid email or password")

      conn
      |> put_flash(:error, message)
      |> render_new()
    end
  end

  defp render_new(conn) do
    redirect(conn, to: ~p"/user/signin")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("eyra-user", "Signed out successfully"))
    |> Account.UserAuth.log_out_user()
  end
end
