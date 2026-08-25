defmodule Systems.Account.Identity.Apple.CallbackPlug do
  import Plug.Conn
  import Systems.Account.Identity.Apple.Helpers, only: [backend_module: 1, apply_defaults: 1]
  use Core.FeatureFlags

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    require_feature(:sign_in_with_apple)
    config = otp_app |> Application.get_env(Systems.Account.Identity.Apple) |> apply_defaults
    session_params = get_session(conn, :sign_in_with_apple)
    config = Keyword.put(config, :session_params, session_params)
    {:ok, %{user: user_info}} = backend_module(config).callback(config, conn.body_params)

    if user = Systems.Account.Identity.Apple.get_user_by_sub(user_info["sub"]) do
      log_in_user(config, conn, user, false)
    else
      apple_userinfo = apple_userinfo(user_info, conn.body_params)

      case Systems.Account.Identity.authenticate_or_transfer(
             Systems.Account.Identity.Apple,
             apple_userinfo
           ) do
        {:transfer, user} ->
          conn
          |> Systems.Account.UserAuth.sign_out_current_user()
          |> put_session(:idp_transfer, %{
            "email" => user.email,
            "idp" => "apple",
            "user_id" => user.id,
            "userinfo" => apple_userinfo
          })
          |> Phoenix.Controller.redirect(to: "/auth/apple/transfer")

        {:ok, %{user: user, first_time?: first_time?}} ->
          log_in_user(config, conn, user, first_time?)

        {:error, changeset} ->
          Systems.Account.Identity.SSOHelpers.handle_registration_error(conn, changeset)
      end
    end
  end

  defp apple_userinfo(user_info, body_params) do
    name = body_params |> Map.get("user", "{}") |> Jason.decode!() |> Map.get("name", %{})

    %{
      "sub" => user_info["sub"],
      "email" => user_info["email"],
      "is_private_email" => user_info["is_private_email"],
      "first_name" => name["firstName"],
      "middle_name" => name["middleName"],
      "last_name" => name["lastName"]
    }
  end

  defp log_in_user(config, conn, user, first_time?) do
    log_in_user = Keyword.get(config, :log_in_user, &Systems.Account.UserAuth.log_in_user/3)
    log_in_user.(conn, user, first_time?)
  end
end
