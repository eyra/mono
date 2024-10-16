defmodule CoreWeb.ErrorController do
  use CoreWeb, :controller

  def access_denied(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> put_view(CoreWeb.ErrorHTML)
    |> render(:"403")
  end
end
