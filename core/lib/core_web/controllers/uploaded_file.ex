defmodule CoreWeb.UploadedFileController do
  use CoreWeb, :controller
  import CoreWeb.FileUploader, only: [get_static_path: 1]

  def get(conn, %{"filename" => name}) do
    path = get_static_path(name)
    send_file(conn, 200, path)
  end
end
