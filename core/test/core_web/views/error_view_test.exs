defmodule CoreWeb.ErrorViewTest do
  use CoreWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 403.html" do
    html = render_to_string(CoreWeb.ErrorView, "403.html", conn: %{})
    assert html =~ "Access Denied"
  end

  test "renders 404.html" do
    html = render_to_string(CoreWeb.ErrorView, "404.html", conn: %{})
    assert html =~ "Page Not Found"
  end

  test "renders 500.html" do
    html = render_to_string(CoreWeb.ErrorView, "500.html", conn: %{})
    assert html =~ "Internal Server Error"
  end

  test "renders 503.html" do
    html = render_to_string(CoreWeb.ErrorView, "503.html", conn: %{})
    assert html =~ "Service Unavailable"
  end
end
