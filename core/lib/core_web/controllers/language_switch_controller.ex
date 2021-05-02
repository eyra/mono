defmodule CoreWeb.LanguageSwitchController do
  use CoreWeb, :controller

  # a long time
  @cookie_age 3_153_600_000

  def index(conn, %{"locale" => locale, "redir" => redir}) do
    conn
    |> Plug.Conn.put_resp_cookie("locale", locale, max_age: @cookie_age)
    |> redirect(to: redir)
  end
end
