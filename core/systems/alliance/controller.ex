defmodule Systems.Alliance.Controller do
  use CoreWeb, :controller

  def callback(conn, %{"id" => _id}) do
    conn
    |> redirect(to: "/assignment/#{1}")
  end
end
