defmodule MicaWeb.HealthController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Mica.Repo

  def get(conn, _params) do
    conn = put_resp_header(conn, "content-type", "text/plain")

    case Ecto.Adapters.SQL.query(Repo, "SELECT 1") do
      {:ok, _} -> resp(conn, 200, "ok")
      _ -> resp(conn, 500, "error connecting to database")
    end
  end
end
