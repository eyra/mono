defmodule Self.Account.SessionController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

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
    case Self.Account.AuthCodeVerifyPage.decode_redeem_token(token) do
      {:ok, %{user_id: nil, email: email} = payload} ->
        register_new_email_user(conn, email, payload)

      {:ok, %{user_id: user_id} = payload} ->
        user = Account.Public.get_user!(user_id)

        conn
        |> stash_return_to(payload)
        |> Account.UserAuth.log_in_user(user, false)

      _ ->
        redeem_failed(conn)
    end
  end

  defp register_new_email_user(conn, email, payload) do
    case Account.Public.register_user_with_email(email, Map.get(payload, :creator?, false)) do
      {:ok, user} ->
        conn
        |> stash_return_to(payload)
        |> Account.UserAuth.log_in_user(user, true)

      {:error, _changeset} ->
        redeem_failed(conn)
    end
  end

  defp redeem_failed(conn) do
    conn
    |> put_flash(:error, dgettext("eyra-user", "auth.session.expired"))
    |> redirect(to: ~p"/user/auth/identify")
  end

  # `log_in_user` reads `:user_return_to` from the session before renewing it.
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
