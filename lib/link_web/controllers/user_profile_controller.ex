defmodule LinkWeb.UserProfileController do
  use LinkWeb, :controller
  alias Link.Users

  def edit(conn, _) do
    user_profile = get_user_profile(conn)

    changeset = Users.change_profile(user_profile)

    render(conn, "edit.html", profile: user_profile, changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"profile" => user_profile_params}) do
    user_profile = get_user_profile(conn)

    case Users.update_profile(user_profile, user_profile_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: Routes.user_profile_path(conn, :edit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", profile: user_profile, changeset: changeset)
    end
  end

  defp get_user_profile(conn) do
    conn
    |> Pow.Plug.current_user()
    |> Users.get_profile()
  end
end
