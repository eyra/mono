defmodule Systems.Account.SettingsController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  alias Systems.Account

  plug(:assign_email_and_password_changesets)

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    %{email: email} = user = conn.assigns.current_user

    case Account.Public.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Account.Public.deliver_update_email_instructions(
          applied_user,
          email,
          &url(conn, ~p"/user/settings/confirm-email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/user/settings")

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Account.Public.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("eyra-user", "password.updated.successfully"))
        |> put_session(:user_return_to, ~p"/user/settings")
        |> Account.UserAuth.log_in_user(user, false)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Account.Public.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, dgettext("eyra-user", "email.changed.successfully"))
        |> redirect(to: ~p"/user/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/user/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Account.Public.change_user_email(user))
    |> assign(:password_changeset, Account.Public.change_user_password(user))
  end
end
