defmodule Systems.Account.UserAuth do
  use CoreWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in Account.UserTokenModel.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_core_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, first_time?, params \\ %{}) do
    token = Account.Public.generate_user_session_token(user)

    redirect_to =
      if first_time?,
        do: ~p"/user/onboarding/terms-and-privacy",
        else: redirect_path_after_signin(conn, user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: redirect_to)
  end

  def log_in_user_without_redirect(conn, user) do
    token = Account.Public.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  @doc """
  Logs the user in for onboarding without redirect.

  Used after signup to auto-login the user before they complete onboarding.
  Preserves the locale in the session.
  """
  def log_in_user_for_onboarding(conn, user, locale) do
    token = Account.Public.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> put_session(Cldr.Plug.PutLocale.session_key(), locale)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. Preserves locale across
  # session renewal.
  defp renew_session(conn) do
    locale = get_session(conn, Cldr.Plug.PutLocale.session_key())

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> maybe_restore_locale(locale)
  end

  defp maybe_restore_locale(conn, nil), do: conn

  defp maybe_restore_locale(conn, locale),
    do: put_session(conn, Cldr.Plug.PutLocale.session_key(), locale)

  @doc """
  Signs out the current user without redirecting.

  Broadcasts a disconnect to any active LiveView session, forgets the
  user (deletes token and remember-me cookie) and renews the session.
  """
  def sign_out_current_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      CoreWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> forget_user()
    |> renew_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    conn
    |> sign_out_current_user()
    |> redirect(to: ~p"/user/signin")
  end

  @doc """
    Removes user token and cookie
  """
  def forget_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Account.Public.delete_session_token(user_token)
    delete_resp_cookie(conn, @remember_me_cookie)
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Account.Public.get_user_by_session_token(user_token)

    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if user = conn.assigns[:current_user] do
      path = signed_in_path(user) || Account.Public.start_page_path(user)

      conn
      |> redirect(to: path)
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:info, dgettext("eyra-ui", "authentication.required.message"))
      |> maybe_store_return_to()
      |> redirect(to: ~p"/user/signin")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp redirect_path_after_signin(conn, user) do
    onboarding_path(user) ||
      get_session(conn, :user_return_to) ||
      signed_in_path(user) ||
      Account.Public.start_page_path(user)
  end

  defp onboarding_path(_), do: nil

  def signed_in_path(%{creator: false}),
    do: path(:member_signed_in_page)

  def signed_in_path(%{creator: true}),
    do: path(:creator_signed_in_page)

  def signed_in_path(_user),
    do: path(:member_signed_in_page)

  defp path(key), do: auth_config(key)

  defp auth_config(key) when is_atom(key) do
    Application.get_env(:core, Systems.Account.UserAuth, [])
    |> Keyword.get(key)
  end
end
