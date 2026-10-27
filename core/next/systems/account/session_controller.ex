defmodule Next.Account.SessionController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.ReturnTo
  alias Next.Account.NativeApp
  alias Systems.Account
  alias Frameworks.Utility.Params
  alias Frameworks.Signal

  def status(conn, _params) do
    status = if conn.assigns[:current_user], do: :no_content, else: :unauthorized

    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(status, "")
  end

  def new(conn, _params) do
    conn
    |> set_return_to()
    |> render_new()
  end

  defp set_return_to(conn) do
    return_to = Map.get(conn.query_params, "return_to")
    if return_to, do: put_session(conn, :user_return_to, return_to), else: conn
  end

  def create(conn, %{"user" => user_params}) do
    create(conn, user_params)
  end

  def create(conn, %{"email" => email, "password" => password} = user_params) do
    require_feature(:password_sign_in)

    if user = Account.Public.get_user_by_email_and_password(email, password) do
      post_action = Params.parse_string_param(user_params, "post_signin_action")

      if post_action do
        Signal.Public.dispatch({:account, :post_signin}, %{user: user, action: post_action})
      end

      Account.UserAuth.log_in_user(conn, user, false, user_params)
    else
      message = dgettext("eyra-user", "Invalid email or password")

      conn
      |> put_flash(:error, message)
      |> render_new()
    end
  end

  def redeem_otp(conn, %{"token" => token}) do
    if feature_enabled?(:otp) do
      do_redeem_otp(conn, token)
    else
      redirect(conn, to: ~p"/user/signin")
    end
  end

  defp do_redeem_otp(conn, token) do
    with {:ok, payload} <- Next.Account.AuthCodeVerifyPage.decode_redeem_token(token),
         {:ok, user, first_time?} <-
           Next.Account.OtpSignin.resolve_user(conn.assigns[:current_user], payload) do
      conn
      |> stash_return_to(payload)
      |> Account.UserAuth.log_in_user(user, first_time?, mobile_session_params(conn))
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("eyra-user", "auth.session.expired"))
        |> redirect(to: ~p"/user/auth/identify")
    end
  end

  # `log_in_user/4` reads `:user_return_to` from the session (via
  # `redirect_path_after_signin/2`) before renewing the session, so
  # placing it here honours the caller's intent for both new users
  # (falls back to onboarding) and existing users (honoured).
  defp stash_return_to(conn, %{return_to: return_to}) do
    case ReturnTo.sanitize(return_to) do
      nil -> conn
      path -> put_session(conn, :user_return_to, path)
    end
  end

  defp stash_return_to(conn, _payload), do: conn

  defp mobile_session_params(conn), do: %{mobile_session?: NativeApp.request?(conn)}

  defp render_new(conn) do
    redirect(conn, to: ~p"/user/signin")
  end

  def delete(conn, _params) do
    redirect_path =
      if NativeApp.request?(conn),
        do: ~p"/user/auth/identify",
        else: ~p"/user/signin"

    conn
    |> put_flash(:info, dgettext("eyra-user", "Signed out successfully"))
    |> Account.UserAuth.sign_out_current_user()
    |> redirect(to: redirect_path)
  end
end
