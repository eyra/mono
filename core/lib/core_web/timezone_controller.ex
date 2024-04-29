defmodule CoreWeb.TimezoneController do
  use CoreWeb, :controller

  def put_session(conn, %{"timezone" => timezone}) do
    conn |> put_session(:timezone, timezone) |> json(%{})
  end
end
