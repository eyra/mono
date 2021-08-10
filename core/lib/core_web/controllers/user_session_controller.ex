defmodule CoreWeb.UserSessionController do
  use CoreWeb, :controller

  import CoreWeb.Gettext

  if feature_enabled?(:signin_with_apple) do
    plug(:setup_sign_in_with_apple, :core when action != :delete)

    defp setup_sign_in_with_apple(conn, otp_app) do
      conf = Application.fetch_env!(otp_app, SignInWithApple)
      SignInWithApple.Helpers.setup_session(conn, conf)
    end
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  if feature_enabled?(:password_sign_in) do
    def create(conn, %{"user" => user_params}) do
      %{"email" => email, "password" => password} = user_params

      if user = Core.Accounts.get_user_by_email_and_password(email, password) do
        CoreWeb.UserAuth.log_in_user(conn, user, user_params)
      else
        message = dgettext("eyra-user", "Invalid email or password")
        render(conn |> put_flash(:error, message), "new.html")
      end
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CoreWeb.UserAuth.log_out_user()
  end
end
