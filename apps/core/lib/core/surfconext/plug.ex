defmodule Core.SurfConext.PlugUtils do
  def oidc_module(config) do
    Keyword.get(config, :oidc_module, Assent.Strategy.OIDC)
  end
end

defmodule Core.SurfConext.AuthorizePlug do
  @moduledoc """
  This controller manages the OpenID Connect flow with SurfConext.

  See this site for more info: https://sp.surfconext.nl/
  """
  import Plug.Conn
  import Core.SurfConext.PlugUtils

  def init(options) when is_list(options), do: options

  def call(conn, config) do
    {:ok, %{url: url, session_params: session_params}} = oidc_module(config).authorize_url(config)

    conn
    |> put_session(:surfconext, session_params)
    |> Phoenix.Controller.redirect(external: url)
  end
end

defmodule Core.SurfConext.CallbackPlug do
  import Plug.Conn
  import Core.SurfConext.PlugUtils

  def init(options) when is_list(options), do: options

  def call(conn, config) do
    session_params = get_session(conn, :surfcontext)

    config = Keyword.put(config, :session_params, session_params)

    {:ok, %{user: surf_user, token: token}} = oidc_module(config).callback(config, conn.params)

    user =
      if user = Core.SurfConext.get_user_by_sub(surf_user["sub"]) do
        user
      else
        with {:ok, userinfo} <- oidc_module(config).fetch_userinfo(config, token),
             {:ok, surfconext_user} <- Core.SurfConext.register_user(userinfo) do
          surfconext_user.user
        end
      end

    CoreWeb.UserAuth.log_in_user(conn, user)
  end
end
