defmodule Systems.Account.Auth.Centerdata.PlugUtils do
  alias Systems.Account.Auth

  def config(otp_app), do: Application.fetch_env!(otp_app, Auth.Centerdata)
  def oidc_module(config), do: Keyword.get(config, :oidc_module, Assent.Strategy.OIDC)

  def log_in_user(config, conn, user, first_time?),
    do:
      Keyword.get(config, :log_in_user, &Systems.Account.UserAuth.log_in_user/3).(
        conn,
        user,
        first_time?
      )
end

defmodule Systems.Account.Auth.Centerdata.AuthorizePlug do
  import Plug.Conn
  import Systems.Account.Auth.Centerdata.PlugUtils
  use Core.FeatureFlags

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    if feature_enabled?(:centerdata_sign_in) do
      config = config(otp_app) |> Keyword.put(:nonce, nonce())

      {:ok, %{url: url, session_params: session_params}} =
        oidc_module(config).authorize_url(config)

      conn
      |> put_session(:centerdata, session_params)
      |> Phoenix.Controller.redirect(external: url)
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp nonce do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end

defmodule Systems.Account.Auth.Centerdata.CallbackController do
  require Logger
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Plug.Conn
  import Systems.Account.Auth.Centerdata.PlugUtils
  use Core.FeatureFlags

  alias Systems.Account.Auth

  def authenticate(conn, params) do
    if feature_enabled?(:centerdata_sign_in) do
      case get_session(conn, :centerdata) do
        nil -> redirect_with_error(conn, "session_not_found")
        session_params -> authenticate(conn, params, session_params)
      end
    else
      conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp authenticate(conn, params, session_params) do
    config =
      config(:core)
      |> Keyword.put(:session_params, session_params)
      |> Keyword.put(:nonce, session_params.nonce)

    with {:ok, %{user: userinfo}} <- oidc_module(config).callback(config, params),
         :ok <- validate_userinfo(userinfo) do
      case Auth.authenticate_or_transfer(Auth.Centerdata, userinfo) do
        {:transfer, user} ->
          conn
          |> Systems.Account.UserAuth.sign_out_current_user()
          |> put_session(:idp_transfer, %{
            "email" => user.email,
            "idp" => "centerdata",
            "user_id" => user.id,
            "userinfo" => userinfo
          })
          |> redirect(to: ~p"/auth/centerdata/transfer")

        {:ok, %{user: user, first_time?: first_time?}} ->
          log_in_user(config, conn, user, first_time?)

        {:error, changeset} ->
          Auth.SSOHelpers.handle_registration_error(conn, changeset)
      end
    else
      reason ->
        Logger.warning("[Centerdata] rejected OIDC callback: #{inspect(reason)}")
        redirect_with_error(conn, "invalid_identity")
    end
  end

  defp validate_userinfo(%{"sub" => sub, "email" => email, "email_verified" => true})
       when is_binary(sub) and is_binary(email),
       do: :ok

  defp validate_userinfo(_userinfo), do: {:error, :missing_verified_identity}

  defp redirect_with_error(conn, error) do
    conn
    |> put_flash(:error, Auth.SSOHelpers.error_message(error))
    |> redirect(to: ~p"/user/signin")
  end
end
