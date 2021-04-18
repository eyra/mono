defmodule CoreWeb.DataLoaderController do
  use CoreWeb, :controller
  alias Core.DataUploader

  def index(conn, %{"id" => script_id}) do
    client_script = DataUploader.get_client_script!(script_id)

    conn
    |> assign(:script, client_script.script)
    |> render("index.html")
  end
end
