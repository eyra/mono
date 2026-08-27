defmodule CoreWeb.FakeAllianceController do
  use CoreWeb,
      {:controller, [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def index(conn, _params) do
    redirect_url = Map.get(conn.query_params, "redirect_url")
    render(conn, "index.html", redirect_url: redirect_url)
  end
end
