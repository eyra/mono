defmodule CoreWeb.ErrorController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def access_denied(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> put_view(CoreWeb.ErrorHTML)
    |> render(:"403")
  end
end
