defmodule Systems.DataDonation.DownloadController do
  use CoreWeb, :controller

  alias Systems.{
    DataDonation
  }

  def download(conn, %{"id" => tool_id}) do
    tool = DataDonation.Context.get_tool!(tool_id)

    conn
    |> assign(:script, tool.script)
    |> render("index.html")
  end

  def download_single(conn, %{"id" => tool_id, "donation_id" => donation_id}) do
    tool = DataDonation.Context.get_tool!(tool_id)

    data =
      DataDonation.Context.list_donations(tool)
      |> Enum.filter(&(Integer.to_string(&1.id) == donation_id))

    send_zip(conn, data)
  end

  def download_all(conn, %{"id" => tool_id}) do
    tool = DataDonation.Context.get_tool!(tool_id)
    data = DataDonation.Context.list_donations(tool)
    send_zip(conn, data)
  end

  def send_zip(conn, data) do
    {:ok, {_, zip_data}} = zip(data)

    conn
    |> put_resp_content_type("application/zip")
    |> put_resp_header("content-disposition", "attachment; filename=\"donated_data.zip\"")
    |> send_resp(200, zip_data)
  end

  def zip(data) when is_list(data) do
    files = Enum.map(data, &{Integer.to_charlist(&1.id, 16) ++ '.json', &1.data})
    :zip.create('download.zip', files, [:memory, {:compress, :all}])
  end
end
