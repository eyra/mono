defmodule MicaWeb.ViewportController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  def put_session(conn, %{"viewport" => viewport}) do
    conn |> put_session(:viewport, viewport) |> json(%{})
  end
end
