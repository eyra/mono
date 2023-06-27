defmodule Systems.DataDonation.CenterdataFakeApiController do
  use CoreWeb, :controller

  def create(
        conn,
        params
      ) do
    path = Routes.live_path(conn, Systems.DataDonation.CenterdataFakeApiPage, params: params)
    redirect(conn, to: path)
  end
end
