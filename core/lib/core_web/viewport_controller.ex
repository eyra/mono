defmodule CoreWeb.ViewportController do
  use CoreWeb, :controller

  def put_session(conn, %{"viewport" => viewport}) do
    conn |> put_session(:viewport, viewport) |> json(%{})
  end
end
