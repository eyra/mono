defmodule GoogleSignIn.PlugUtils do
  def google_module(config) do
    Keyword.get(config, :google_module, Assent.Strategy.Google)
  end
end

defmodule GoogleSignIn.AuthorizePlug do
  @moduledoc """
  This controller manages the OpenID Connect flow with SurfConext.

  See this site for more info: https://sp.google_sign_in.nl/
  """
  import Plug.Conn
  import GoogleSignIn.PlugUtils

  def init(options) when is_list(options), do: options

  def call(conn, config) do
    {:ok, %{url: url, session_params: session_params}} =
      google_module(config).authorize_url(config)

    conn
    |> put_session(:google_sign_in, session_params)
    |> Phoenix.Controller.redirect(external: url)
  end
end

defmodule(GoogleSignIn.CallbackPlug) do
  import Plug.Conn
  import GoogleSignIn.PlugUtils

  def init(options) when is_list(options), do: options

  def call(conn, config) do
    session_params = get_session(conn, :google_sign_in)

    config = Keyword.put(config, :session_params, session_params)

    {:ok, %{user: google_user}} = google_module(config).callback(config, conn.params)

    user = GoogleSignIn.get_user_by_sub(google_user["sub"]) || register_user(google_user)

    CoreWeb.UserAuth.log_in_user(conn, user)
  end

  defp register_user(info) do
    {:ok, google_sign_in_user} = GoogleSignIn.register_user(info)
    google_sign_in_user.user
  end
end
