defmodule CoreWeb.DataDonationController do
  use CoreWeb, :controller
  alias Core.DataDonation.Tools

  def index(conn, %{"id" => tool_id}) do
    tool = Tools.get!(tool_id)

    conn
    |> assign(:script, tool.script)
    |> render("index.html")
  end
end
