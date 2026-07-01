defmodule Core.SurfConext.PlugUtils do
  def config(otp_app) do
    Application.get_env(otp_app, Core.SurfConext)
  end

  def oidc_module(config) do
    Keyword.get(config, :oidc_module, Assent.Strategy.OIDC)
  end

  def log_in_user(config, conn, user, first_time?) do
    log_in_user = Keyword.get(config, :log_in_user, &Systems.Account.UserAuth.log_in_user/3)
    log_in_user.(conn, user, first_time?)
  end
end

defmodule Core.SurfConext.AuthorizePlug do
  @moduledoc """
  This controller manages the OpenID Connect flow with SurfConext.

  See this site for more info: https://sp.surfconext.nl/
  """
  import Plug.Conn
  import Core.SurfConext.PlugUtils

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    config = config(otp_app)

    {:ok, %{url: url, session_params: session_params}} = oidc_module(config).authorize_url(config)

    conn
    |> put_session(:surfconext, session_params)
    |> Phoenix.Controller.redirect(external: url)
  end
end

defmodule Core.SurfConext.CallbackController do
  require Logger
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Plug.Conn
  import Core.SurfConext.PlugUtils

  def authenticate(conn, params) do
    Logger.debug("SURFconext params: #{inspect(params)}")
    session_params = get_session(conn, :surfconext)

    if is_nil(session_params) do
      log_session_not_found(conn)
      redirect_with_error(conn, "session_not_found")
    else
      do_authenticate(conn, params, session_params)
    end
  end

  defp log_session_not_found(conn) do
    Logger.error("[SurfConext] OAuth callback without session state",
      request_path: conn.request_path,
      query_string: conn.query_string,
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    )
  end

  defp redirect_with_error(conn, error) do
    conn
    |> put_flash(:error, Core.SSOHelpers.error_message(error))
    |> redirect(to: ~p"/user/signin")
  end

  defp do_authenticate(conn, params, session_params) do
    config = config(:core) |> Keyword.put(:session_params, session_params)

    {:ok, %{token: token}} = oidc_module(config).callback(config, params)

    with {:ok, userinfo} <- oidc_module(config).fetch_userinfo(config, token) do
      Logger.debug("SURFconext userinfo: #{inspect(userinfo)}")

      case Core.Identity.authenticate(Core.SurfConext, userinfo) do
        {:ok, %{user: user, first_time?: first_time?}} ->
          log_in_user(config, conn, user, first_time?)

        {:error, changeset} ->
          Core.SSOHelpers.handle_registration_error(conn, changeset)
      end
    end
  end
end
