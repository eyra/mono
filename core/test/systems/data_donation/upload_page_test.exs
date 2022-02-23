defmodule Systems.DataDonation.UploadPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Mox

  alias Systems.DataDonation.{UploadPage}

  describe "public page" do
    test "embedding of Python code on the page", %{conn: conn} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, UploadPage, "a-participant"))
      assert html =~ "import pandas"
    end

    test "redirect after upload", %{conn: conn} do
      Systems.DataDonation.MockStorageBackend
      |> expect(:store, fn _participant_id, "Some extracted data" -> nil end)

      {:ok, view, _html} = live(conn, Routes.live_path(conn, UploadPage, "a-participant"))

      assert {:error, {:live_redirect, %{kind: :push}}} =
               view
               |> element("form")
               |> render_submit(%{data: "Some extracted data"})
    end
  end
end
