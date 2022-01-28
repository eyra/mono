defmodule Systems.DataDonation.UploadPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Mox

  alias Systems.DataDonation.{UploadPage, ToolModel}

  setup do
    {:ok, tool: Factories.insert!(:data_donation_tool, %{script: "print 'Hello World!'"})}
  end

  describe "public page" do
    test "embedding of Python code on the page", %{conn: conn, tool: tool} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, UploadPage, tool.id))
      assert html =~ String.replace(tool.script, "'", "&#39;")
    end

    test "redirect after upload", %{conn: conn, tool: tool} do
      Systems.DataDonation.MockStorageBackend
      |> expect(:store, fn %ToolModel{}, "Some extracted data" -> nil end)

      {:ok, view, html} = live(conn, Routes.live_path(conn, UploadPage, tool.id))

      assert {:error, {:live_redirect, %{kind: :push}}} =
               view
               |> element("form")
               |> render_submit(%{data: "Some extracted data"})
    end
  end
end
