defmodule Systems.DataDonation.UploadPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Mox

  alias Systems.DataDonation.{UploadPage}

  describe "public page" do
    test "embedding of Python code on the page", %{conn: conn} do
      path = Routes.live_path(conn, UploadPage, 1, session: %{participant: 1})

      {:ok, _view, html} = live(conn, path)
      assert html =~ "import pandas"
    end

    test "redirect after donate", %{conn: conn} do
      Systems.DataDonation.MockStorageBackend
      |> expect(:store, fn _state, _vm, "Some extracted data" -> nil end)

      path = Routes.live_path(conn, UploadPage, 1, session: %{participant: 1})
      {:ok, view, _html} = live(conn, path)

      assert {:error, {:live_redirect, %{kind: :push}}} =
               view
               |> element("#donate-form")
               |> render_submit(%{data: "Some extracted data"})
    end

    test "redirect after decline", %{conn: conn} do
      Systems.DataDonation.MockStorageBackend
      |> expect(:store, fn _state, _vm, "Some extracted data" -> nil end)

      path = Routes.live_path(conn, UploadPage, 1, session: %{participant: 1})
      {:ok, view, _html} = live(conn, path)

      assert {:error, {:live_redirect, %{kind: :push}}} =
               view
               |> element("#decline-form")
               |> render_submit(%{data: "Some extracted data"})
    end
  end
end
