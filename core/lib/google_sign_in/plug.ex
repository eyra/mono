defmodule GoogleSignIn.PlugUtils do
  def config(otp_app) do
    Application.get_env(otp_app, GoogleSignIn)
  end

  def google_module(config) do
    Keyword.get(config, :google_module, Assent.Strategy.Google)
  end

  def log_in_user(config, conn, user, first_time?) do
    log_in_user = Keyword.get(config, :log_in_user, &Systems.Account.UserAuth.log_in_user/3)
    log_in_user.(conn, user, first_time?)
  end
end

defmodule GoogleSignIn.AuthorizePlug do
  import Plug.Conn
  import GoogleSignIn.PlugUtils

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(%{params: conn_params} = conn, otp_app) do
    config = config(otp_app)

    {:ok, %{url: url, session_params: session_params}} =
      google_module(config).authorize_url(config)

    conn
    |> put_session(:google_sign_in, Map.merge(conn_params, session_params))
    |> set_return_to()
    |> Phoenix.Controller.redirect(external: url)
  end

  defp set_return_to(conn) do
    return_to = Map.get(conn.query_params, "return_to")
    if return_to, do: put_session(conn, :user_return_to, return_to), else: conn
  end
end

defmodule GoogleSignIn.CallbackPlug do
  import Plug.Conn
  import GoogleSignIn.PlugUtils
  use Core.FeatureFlags

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    session_params = get_session(conn, :google_sign_in)
    creator? = Map.get(session_params || %{}, "creator", nil) == "true"

    config = config(otp_app) |> Keyword.put(:session_params, session_params)

    {:ok, %{user: google_user}} = google_module(config).callback(config, conn.params)

    if !feature_enabled?(:member_google_sign_in) && !admin?(google_user) do
      throw("Google login is disabled")
    end

    {user, first_time?} =
      if user = GoogleSignIn.get_user_by_sub(google_user["sub"]) do
        {user, false}
      else
        {register_user(google_user, creator?), true}
      end

    log_in_user(config, conn, user, first_time?)
  end

  defp register_user(info, creator?) do
    {:ok, google_sign_in_user} = GoogleSignIn.register_user(info, creator?)
    google_sign_in_user.user
  end

  defp admin?(%{"email" => email}), do: Systems.Admin.Public.admin?(email)
end
