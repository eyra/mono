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
    config = config(otp_app) |> with_login_hint(conn_params)

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

  defp with_login_hint(config, %{"login_hint" => hint}) when is_binary(hint) and hint != "" do
    # Don't blow away Assent.Strategy.Google's default scope ("email profile") —
    # without it Google's callback omits the email and user registration fails.
    existing = Keyword.get(config, :authorization_params, [])

    merged =
      existing
      |> Keyword.put_new(:scope, "email profile")
      |> Keyword.put(:login_hint, hint)

    Keyword.put(config, :authorization_params, merged)
  end

  defp with_login_hint(config, _), do: config
end

defmodule GoogleSignIn.CallbackPlug do
  import Plug.Conn
  import GoogleSignIn.PlugUtils
  require Logger
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes
  use Core.FeatureFlags

  alias Frameworks.Utility.Params
  alias Frameworks.Signal

  def init(otp_app) when is_atom(otp_app), do: otp_app

  def call(conn, otp_app) do
    session_params = get_session(conn, :google_sign_in)

    if is_nil(session_params) do
      log_session_not_found(conn)
      redirect_with_error(conn, "session_not_found")
    else
      authenticate(conn, otp_app, session_params)
    end
  end

  defp log_session_not_found(conn) do
    Logger.error("[GoogleSignIn] OAuth callback without session state",
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

  defp authenticate(conn, otp_app, session_params) do
    creator? = Params.parse_creator(session_params)
    post_action = Params.parse_string_param(session_params, "post_signin_action")

    config = config(otp_app) |> Keyword.put(:session_params, session_params)

    {:ok, %{user: google_user}} = google_module(config).callback(config, conn.params)

    if !feature_enabled?(:member_google_sign_in) && !admin?(google_user) do
      throw("Google login is disabled")
    end

    case Core.Identity.authenticate(GoogleSignIn, google_user, %{creator: creator?}) do
      {:ok, %{user: user, first_time?: first_time?}} ->
        dispatch_post_signin_action(user, post_action)
        log_in_user(config, conn, user, first_time?)

      {:error, changeset} ->
        Core.SSOHelpers.handle_registration_error(conn, changeset)
    end
  end

  defp dispatch_post_signin_action(_user, nil), do: :ok

  defp dispatch_post_signin_action(user, action) do
    Signal.Public.dispatch({:account, :post_signin}, %{user: user, action: action})
  end

  defp admin?(%{"email" => email}), do: Systems.Admin.Public.admin?(email)
end
