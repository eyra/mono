defmodule SignInWithApple.CallbackPlug do
  import Plug.Conn
  import SignInWithApple.Helpers, only: [backend_module: 1, apply_defaults: 1]
  use Core.FeatureFlags

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    require_feature(:sign_in_with_apple)
    config = otp_app |> Application.get_env(SignInWithApple) |> apply_defaults
    session_params = get_session(conn, :sign_in_with_apple)
    config = Keyword.put(config, :session_params, session_params)
    {:ok, %{user: user_info}} = backend_module(config).callback(config, conn.body_params)

    if user = SignInWithApple.get_user_by_sub(user_info["sub"]) do
      log_in_user(config, conn, user, false)
    else
      {:ok, user_name_params} = conn.body_params["user"] |> Jason.decode!() |> Map.fetch("name")

      case SignInWithApple.register_user(%{
             sub: user_info["sub"],
             email: user_info["email"],
             is_private_email: user_info["is_private_email"],
             first_name: user_name_params["firstName"],
             middle_name: user_name_params["middleName"],
             last_name: user_name_params["lastName"]
           }) do
        {:ok, signed_in_apple_user} ->
          log_in_user(config, conn, signed_in_apple_user.user, true)

        {:error, changeset} ->
          Core.SSOHelpers.handle_registration_error(conn, changeset)
      end
    end
  end

  defp log_in_user(config, conn, user, first_time?) do
    log_in_user = Keyword.get(config, :log_in_user, &Systems.Account.UserAuth.log_in_user/3)
    log_in_user.(conn, user, first_time?)
  end
end
