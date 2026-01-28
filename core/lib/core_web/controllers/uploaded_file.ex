defmodule CoreWeb.UploadedFileController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  import CoreWeb.FileUploader, only: [get_upload_path: 1]

  def get(conn, %{"filename" => name}) do
    path = get_upload_path(name)

    if File.exists?(path) do
      send_file(conn, 200, path)
    else
      send_resp(conn, 404, "Not found")
    end
  end
end
