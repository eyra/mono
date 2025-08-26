defmodule CoreWeb.TimezoneController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def put_session(conn, %{"timezone" => timezone}) do
    conn |> put_session(:timezone, timezone) |> json(%{})
  end
end
