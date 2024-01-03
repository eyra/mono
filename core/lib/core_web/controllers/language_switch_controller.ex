defmodule CoreWeb.LanguageSwitchController do
  use CoreWeb, :controller

  # a long time
  @cookie_age 3_153_600_000

  def index(conn, %{"locale" => locale, "redir" => redir}) do
    conn
    |> switch_to(locale)
    |> redirect(to: redir)
  end

  def switch_to(conn, locale) do
    Plug.Conn.put_resp_cookie(conn, "locale", locale, max_age: @cookie_age)
  end
end
