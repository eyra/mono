defmodule Systems.DataDonation.UploadPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Mox

  alias Systems.DataDonation.{UploadPage}

  describe "public page" do
    test "embedding of Python code on the page", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"flow" => "1", "storage_info" => %{}})

      {:ok, _view, html} = live(conn, Routes.live_path(conn, UploadPage))
      assert html =~ "import pandas"
    end

    test "redirect after upload", %{conn: conn} do
      Systems.DataDonation.MockStorageBackend
      |> expect(:store, fn _info, _vm, "Some extracted data" -> nil end)

      conn =
        conn
        |> init_test_session(%{"flow" => "1", "storage_info" => %{}})

      {:ok, view, _html} = live(conn, Routes.live_path(conn, UploadPage))

      assert {:error, {:live_redirect, %{kind: :push}}} =
               view
               |> element("form")
               |> render_submit(%{data: "Some extracted data"})
    end
  end
end
