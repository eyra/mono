defmodule LinkWeb.FakeSurveyController do
  use LinkWeb, :controller

  def index(conn, _params) do
    redirect_url = conn.query_params |> Map.get("redirect_url")
    render(conn, "index.html", redirect_url: redirect_url)
  end
end
