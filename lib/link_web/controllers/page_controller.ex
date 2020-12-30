defmodule LinkWeb.PageController do
  use LinkWeb, :controller
  alias Link.Users
  alias Link.Users.User

  def index(conn, _params) do
    user_profile = get_user_profile(conn)
    render(conn, "index.html", profile: user_profile)
  end

  defp get_user_profile(%Plug.Conn{} = conn) do
    conn
    |> Pow.Plug.current_user()
    |> get_user_profile()
  end

  defp get_user_profile(%User{} = user) do
    user
    |> Users.get_profile()
  end

  defp get_user_profile(nil) do
    nil
  end
end
