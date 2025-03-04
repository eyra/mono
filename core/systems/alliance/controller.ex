defmodule Systems.Alliance.Controller do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  def callback(conn, %{"id" => _id}) do
    conn
    |> redirect(to: "/assignment/#{1}")
  end
end
