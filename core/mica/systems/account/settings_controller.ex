defmodule Systems.Account.SettingsController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Systems.Account

  plug(:assign_password_changeset)

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Account.Public.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("eyra-user", "password.updated.successfully"))
        |> put_session(:user_return_to, ~m"/user/settings")
        |> Account.UserAuth.log_in_user(user, false)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_password_changeset(conn, _opts) do
    user = conn.assigns.current_user
    assign(conn, :password_changeset, Account.Public.change_user_password(user))
  end
end
