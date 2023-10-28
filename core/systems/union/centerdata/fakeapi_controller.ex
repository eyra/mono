defmodule Systems.Union.Centerdata.FakeApiController do
  use CoreWeb, :controller

  def create(
        conn,
        params
      ) do
    path = Routes.live_path(conn, Systems.Union.Centerdata.FakeApiPage, params: params)
    redirect(conn, to: path)
  end
end
