defmodule Next.Home.LandingPageController do
  use CoreWeb, :controller

  def show(conn, _) do
    render(conn, "show.html")
  end

  def layout(_), do: false
end
