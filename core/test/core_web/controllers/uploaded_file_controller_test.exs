defmodule CoreWeb.UploadedFileControllerTest do
  use CoreWeb.ConnCase, async: true

  alias CoreWeb.UploadedFileController

  describe "get/2" do
    test "returns 200 and file content when file exists", %{conn: conn} do
      # Create a temporary test file in the upload directory
      upload_path = Application.get_env(:core, :upload_path, "priv/static/uploads")
      File.mkdir_p!(upload_path)

      filename = "test-file-123.txt"
      file_path = Path.join(upload_path, filename)
      File.write!(file_path, "test content")

      try do
        conn = UploadedFileController.get(conn, %{"filename" => filename})
        assert conn.status == 200
      after
        File.rm(file_path)
      end
    end

    test "returns 404 when file does not exist", %{conn: conn} do
      conn = UploadedFileController.get(conn, %{"filename" => "nonexistent-file-12345.txt"})
      assert conn.status == 404
      assert conn.resp_body == "Not Found"
    end

    test "returns 404 for invalid characters in filename", %{conn: conn} do
      conn = get(conn, ~p"/uploads/upload.php")
      assert conn.status == 404
    end

    test "returns 404 for uppercase letters in filename", %{conn: conn} do
      conn = get(conn, ~p"/uploads/Test.txt")
      assert conn.status == 404
    end

    test "returns 404 for non-existent files with valid filename", %{conn: conn} do
      conn = get(conn, ~p"/uploads/non-existent-file.txt")
      assert conn.status == 404
    end
  end
end
