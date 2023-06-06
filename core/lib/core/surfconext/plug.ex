defmodule Core.SurfConext.PlugUtils do
  def config(otp_app) do
    Application.get_env(otp_app, Core.SurfConext)
  end

  def oidc_module(config) do
    Keyword.get(config, :oidc_module, Assent.Strategy.OIDC)
  end

  def log_in_user(config, conn, user, first_time?) do
    log_in_user = Keyword.get(config, :log_in_user, &CoreWeb.UserAuth.log_in_user/3)
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
  use Phoenix.Controller, namespace: CoreWeb
  use CoreWeb, :verified_routes

  import Core.SurfConext.PlugUtils

  def authenticate(conn, params) do
    Logger.debug("SURFconext params: #{inspect(params)}")
    session_params = get_session(conn, :surfcontext)

    config = config(:core) |> Keyword.put(:session_params, session_params)

    {:ok, %{user: surf_user, token: token}} = oidc_module(config).callback(config, params)
    Logger.debug("SURFconext user: #{inspect(surf_user)}")

    Logger.debug(
      "SURFconext oidc info: #{inspect(oidc_module(config).fetch_userinfo(config, token))}"
    )

    authenticate(config, conn, token, surf_user)
  end

  defp authenticate(config, conn, token, surf_user) do
    if user = Core.SurfConext.get_user_by_sub(surf_user["sub"]) do
      update_user(config, conn, user, token)
    else
      register_user(config, conn, token)
    end
  end

  defp update_user(config, conn, user, token) do
    with {:ok, userinfo} <- fetch_userinfo(config, token) do
      Core.SurfConext.update_user(user, userinfo)
    end

    log_in_user(config, conn, user, false)
  end

  defp register_user(config, conn, token) do
    with {:ok, userinfo} <- fetch_userinfo(config, token) do
      case(Core.SurfConext.register_user(userinfo)) do
        {:ok, surfconext_user} ->
          log_in_user(config, conn, surfconext_user.user, true)

        {:error, changeset} ->
          Enum.reduce(changeset.errors, conn, fn {_, {message, _}}, conn ->
            put_flash(conn, :error, message)
          end)
          |> redirect(to: ~p"/user/signin")
      end
    end
  end

  defp fetch_userinfo(config, token) do
    oidc_module(config).fetch_userinfo(config, token)
  end
end
