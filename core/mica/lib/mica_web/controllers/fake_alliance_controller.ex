defmodule MicaWeb.FakeAllianceController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  def index(conn, _params) do
    redirect_url = conn.query_params |> Map.get("redirect_url")
    render(conn, "index.html", redirect_url: redirect_url)
  end
end
