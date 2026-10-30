defmodule Systems.Alliance.Controller do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  def callback(conn, %{"id" => _id}) do
    conn
    |> redirect(to: "/assignment/#{1}")
  end
end
