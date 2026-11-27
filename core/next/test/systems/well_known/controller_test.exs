defmodule Next.Systems.WellKnown.ControllerTest do
  # Not async: the assetlinks tests change the application config.
  use NextWeb.ConnCase, async: false

  @fingerprint_a Enum.map_join(1..32, ":", fn _ -> "AB" end)
  @fingerprint_b Enum.map_join(1..32, ":", fn _ -> "0F" end)

  test "serves the apple-app-site-association as JSON without a redirect or session", %{
    conn: conn
  } do
    conn = get(conn, "/.well-known/apple-app-site-association")

    assert ["application/json" <> _] = get_resp_header(conn, "content-type")
    assert get_resp_header(conn, "set-cookie") == []

    assert %{"webcredentials" => %{"apps" => apps}} = json_response(conn, 200)

    assert "XNWQJGGM96.co.eyra.next" in apps
    assert "XNWQJGGM96.co.eyra.next.dev" in apps
  end

  # For now the apps open no page from outside: invitation links, panel links and the
  # survey return link all stay in the browser (sprint decision, 25 Nov).
  test "lists no app links", %{conn: conn} do
    refute Map.has_key?(
             conn |> get("/.well-known/apple-app-site-association") |> json_response(200),
             "applinks"
           )
  end

  describe "assetlinks.json" do
    test "vouches for each configured package with its own fingerprints", %{conn: conn} do
      put_links([
        {"co.eyra.next", @fingerprint_a},
        {"co.eyra.next.dev", @fingerprint_b},
        {"co.eyra.next", @fingerprint_b}
      ])

      conn = get(conn, "/.well-known/assetlinks.json")

      assert ["application/json" <> _] = get_resp_header(conn, "content-type")
      assert get_resp_header(conn, "set-cookie") == []

      assert [
               %{
                 "relation" => ["delegate_permission/common.handle_all_urls"],
                 "target" => %{
                   "namespace" => "android_app",
                   "package_name" => "co.eyra.next",
                   "sha256_cert_fingerprints" => [@fingerprint_a, @fingerprint_b]
                 }
               },
               %{
                 "target" => %{
                   "package_name" => "co.eyra.next.dev",
                   "sha256_cert_fingerprints" => [@fingerprint_b]
                 }
               }
             ] = json_response(conn, 200)
    end

    test "is not found without a configured app", %{conn: conn} do
      assert conn |> get("/.well-known/assetlinks.json") |> response(404) == ""
    end
  end

  defp put_links(links) do
    Mica.Env.put(:android_app_links, links)
    on_exit(fn -> Application.delete_env(:mica, :android_app_links) end)
  end
end
