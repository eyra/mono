defmodule CoreWeb.ViewportController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def put_session(conn, %{"viewport" => viewport}) do
    conn |> put_session(:viewport, viewport) |> json(%{})
  end
end
