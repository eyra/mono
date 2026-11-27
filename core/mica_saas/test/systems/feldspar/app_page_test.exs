defmodule MicaSaas.Systems.Feldspar.AppPageTest do
  use MicaSaasWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "render an app page" do
    test "renders page with iframe", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~m"/feldspar/apps/test")
      assert html =~ "<iframe"
    end

    test "lets the app use the microphone", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~m"/feldspar/apps/test")
      assert html =~ ~s(allow="microphone")
    end
  end

  describe "handle app_event" do
    test "can receive random app_event data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~m"/feldspar/apps/test")

      assert render_hook(view, :feldspar_event, %{unexpected_key: "some data"}) =~
               "Unsupported "
    end
  end
end
