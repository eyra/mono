defmodule CoreWeb.ErrorHTMLTest do
  use CoreWeb.ConnCase, async: true

  test "renders 403.html", %{conn: conn} do
    html = Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "403", "html", conn: conn)
    assert html =~ "Unfortunately, you don't have access to this page."
  end

  test "renders 404.html", %{conn: conn} do
    html = Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "404", "html", conn: conn)
    assert html =~ "Unfortunately, this page is unavailable."
  end

  test "renders 500.html", %{conn: conn} do
    html = Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "500", "html", conn: conn)
    assert html =~ "Internal Server Error"
  end

  test "renders 503.html", %{conn: conn} do
    html =
      Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "503", "html",
        conn: conn,
        details: "details"
      )

    assert html =~ "Service Unavailable"
  end
end
