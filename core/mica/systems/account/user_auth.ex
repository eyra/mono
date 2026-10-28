defmodule Systems.Account.UserAuth do
  use CoreWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.ReturnTo
  alias Systems.Account

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in Account.UserTokenModel.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_core_web_user_remember_me"
  @remember_me_options [sign: true, http_only: true, max_age: @max_age, same_site: "Lax"]

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
    token = Account.Public.generate_user_session_token(user, session_type(params))

    # For first-time users, we always land on onboarding — but if the caller
    # stashed a `:user_return_to` (e.g. an affiliate CTA that carried
    # `?return_to=/pool/panl/join` into the OTP flow), we forward it as a URL
    # param so onboarding can honour it on its final step. Existing users go
    # straight to their return_to via `redirect_path_after_signin/2`.
    redirect_to =
      if first_time? do
        ReturnTo.append(~p"/user/onboarding", get_session(conn, :user_return_to))
      else
        redirect_path_after_signin(conn, user)
      end

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

  defp maybe_write_remember_me_cookie(conn, token, %{mobile_session?: true}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  defp session_type(%{mobile_session?: true}), do: :mobile
  defp session_type(_params), do: :browser

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

    conn
    |> maybe_renew_mobile_session(user_token, user)
    |> assign(:current_user, user)
  end

  defp ensure_user_token(conn) do
    conn = fetch_cookies(conn, signed: [@remember_me_cookie])

    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  defp maybe_renew_mobile_session(conn, _user_token, nil), do: conn

  defp maybe_renew_mobile_session(conn, user_token, _user) do
    if Account.Public.renew_mobile_session_token(user_token) and
         conn.cookies[@remember_me_cookie] == user_token do
      put_resp_cookie(conn, @remember_me_cookie, user_token, @remember_me_options)
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if user = conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(user))
      |> halt()
    else
      conn
    end
  end

  # archplan: guard=authn
  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts), do: require_authenticated(conn, :user)

  @doc """
  Like `require_authenticated_user/2`, but sends signed-out visitors to the
  participant entry page with the requested path as `return_to`. Used for
  assignment invitation links.
  """
  def require_authenticated_participant(conn, _opts),
    do: require_authenticated(conn, :participant)

  @doc """
  Like `require_authenticated_user/2`, for pages participants open (tasks,
  pool and lab pages). Signed-out visitors go to the SaaS's
  `member_sign_in_page/1`.
  """
  def require_authenticated_member(conn, _opts), do: require_authenticated(conn, :member)

  defp require_authenticated(conn, entry) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:info, dgettext("eyra-ui", "authentication.required.message"))
      |> maybe_store_return_to()
      |> redirect(to: signin_path(conn, entry))
      |> halt()
    end
  end

  defp signin_path(_conn, :user), do: Core.SaaS.module().sign_in_page()

  defp signin_path(conn, :participant),
    do: ReturnTo.append(~p"/user/auth/identify/participant", current_path(conn))

  defp signin_path(conn, :member), do: Core.SaaS.module().member_sign_in_page(current_path(conn))

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp redirect_path_after_signin(conn, user) do
    onboarding_path(user) ||
      get_session(conn, :user_return_to) ||
      signed_in_path(user)
  end

  defp onboarding_path(_), do: nil

  def signed_in_path(%{creator: true}), do: Core.SaaS.module().signed_in_page(:creator)
  def signed_in_path(_user), do: Core.SaaS.module().signed_in_page(:member)
end
