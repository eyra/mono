defmodule CoreWeb.UploadedFileControllerTest do
  use CoreWeb.ConnCase, async: true

  describe "get/2" do
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
