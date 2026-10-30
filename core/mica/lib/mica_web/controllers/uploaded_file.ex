defmodule MicaWeb.UploadedFileController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  import MicaWeb.FileUploader, only: [get_upload_path: 1]

  def get(conn, %{"filename" => name}) do
    try do
      path = get_upload_path(name)

      if File.exists?(path) do
        send_file(conn, 200, path)
      else
        send_resp(conn, 404, "Not Found")
      end
    catch
      :invalid_filename ->
        send_resp(conn, 404, "Not Found")
    end
  end
end
