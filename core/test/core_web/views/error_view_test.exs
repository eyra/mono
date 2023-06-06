defmodule CoreWeb.ErrorHTMLTest do
  use CoreWeb.ConnCase, async: true

  test "renders 403.html", %{conn: conn} do
    html = Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "403", "html", conn: conn)
    assert html =~ "Je hebt helaas geen toegang tot deze pagina"
  end

  test "renders 404.html", %{conn: conn} do
    html = Phoenix.Template.render_to_string(CoreWeb.ErrorHTML, "404", "html", conn: conn)
    assert html =~ "Deze pagina is helaas niet beschikbaar"
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
