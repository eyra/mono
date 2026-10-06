defmodule Next.WellKnownControllerTest do
  use CoreWeb.ConnCase, async: true

  test "serves the apple-app-site-association as JSON without a redirect or session", %{
    conn: conn
  } do
    conn = get(conn, "/.well-known/apple-app-site-association")

    assert ["application/json" <> _] = get_resp_header(conn, "content-type")
    assert get_resp_header(conn, "set-cookie") == []

    assert %{"applinks" => %{"details" => [%{"appIDs" => app_ids, "components" => components}]}} =
             json_response(conn, 200)

    assert "XNWQJGGM96.co.eyra.next" in app_ids
    assert "XNWQJGGM96.co.eyra.next.dev" in app_ids
    assert components == [%{"/" => "/assignment/*"}]
  end
end
