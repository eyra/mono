defmodule Next.Account.SessionController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Frameworks.Utility.Params
  alias Frameworks.Signal

  plug(:setup_sign_in_with_apple, :core when action != :delete)

  defp setup_sign_in_with_apple(conn, otp_app) do
    if feature_enabled?(:signin_with_apple) do
      conf = Application.fetch_env!(otp_app, SignInWithApple)
      SignInWithApple.Helpers.setup_session(conn, conf)
    end
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
    case Next.Account.AuthCodeVerifyPage.decode_redeem_token(token) do
      {:ok, %{user_id: nil, email: email} = payload} ->
        handle_new_email_redeem(conn, email, payload)

      {:ok, %{user_id: user_id} = payload} ->
        user = Account.Public.get_user!(user_id)

        conn
        |> stash_return_to(payload)
        |> Account.UserAuth.log_in_user(user, false)

      _ ->
        conn
        |> put_flash(:error, dgettext("eyra-user", "auth.session.expired"))
        |> redirect(to: ~p"/user/auth/identify")
    end
  end

  # When the redeem token was minted for an email that had no user yet, we
  # normally register a fresh Account.User. But if a provisional user is
  # already logged in — an affiliate synth account that never had a real
  # email — link the real email to *that* user instead. Without this,
  # completing auth from the finished-page "Join Panl" CTA would leave the
  # synth affiliate record behind and mint a new duplicate user.
  defp handle_new_email_redeem(
         %{assigns: %{current_user: %Account.User{} = user}} = conn,
         email,
         payload
       ) do
    if EmailSignUp.provisional?(user) do
      case EmailSignUp.link(user, email) do
        {:ok, linked_user} ->
          conn
          |> stash_return_to(payload)
          |> Account.UserAuth.log_in_user(linked_user, false)

        {:error, _} ->
          register_new_email_user(conn, email, payload)
      end
    else
      register_new_email_user(conn, email, payload)
    end
  end

  defp handle_new_email_redeem(conn, email, payload),
    do: register_new_email_user(conn, email, payload)

  defp register_new_email_user(conn, email, payload) do
    case Account.Public.register_user_with_email(email) do
      {:ok, user} ->
        conn
        |> stash_return_to(payload)
        |> Account.UserAuth.log_in_user(user, true)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, dgettext("eyra-user", "auth.session.expired"))
        |> redirect(to: ~p"/user/auth/identify")
    end
  end

  # `log_in_user/4` reads `:user_return_to` from the session (via
  # `redirect_path_after_signin/2`) before renewing the session, so
  # placing it here honours the caller's intent for both new users
  # (falls back to onboarding) and existing users (honoured).
  defp stash_return_to(conn, %{return_to: "/" <> _rest = path}),
    do: put_session(conn, :user_return_to, path)

  defp stash_return_to(conn, _payload), do: conn

  defp render_new(conn) do
    redirect(conn, to: ~p"/user/signin")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("eyra-user", "Signed out successfully"))
    |> Account.UserAuth.log_out_user()
  end
end
