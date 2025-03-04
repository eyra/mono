defmodule Systems.Assignment.Centerdata.FakeApiController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def create(
        conn,
        params
      ) do
    redirect(conn, to: ~p"/assignment/centerdata/fakeapi/page?#{params}")
  end
end
