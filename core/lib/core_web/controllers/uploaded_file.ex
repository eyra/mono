defmodule CoreWeb.UploadedFileController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  import CoreWeb.FileUploader, only: [get_upload_path: 1]

  def get(conn, %{"filename" => name}) do
    path = get_upload_path(name)
    send_file(conn, 200, path)
  end
end
