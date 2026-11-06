defmodule MicaWeb.ErrorController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  def access_denied(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> put_view(MicaWeb.ErrorHTML)
    |> render(:"403")
  end

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(MicaWeb.ErrorHTML)
    |> render(:"404")
  end
end
