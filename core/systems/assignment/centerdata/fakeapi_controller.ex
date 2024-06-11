defmodule Systems.Assignment.Centerdata.FakeApiController do
  use CoreWeb, :controller

  def create(
        conn,
        params
      ) do
    redirect(conn, to: ~p"/assignment/centerdata/fakeapi/page?#{params}")
  end
end
