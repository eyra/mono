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

    assert %{"applinks" => %{"details" => [%{"appIDs" => app_ids, "components" => components}]}} =
             json_response(conn, 200)

    assert "XNWQJGGM96.co.eyra.next" in app_ids
    assert "XNWQJGGM96.co.eyra.next.dev" in app_ids
    assert components == [%{"/" => "/assignment/*"}]
  end

  describe "assetlinks.json" do
    test "lists every package with the configured fingerprints", %{conn: conn} do
      put_fingerprints("#{@fingerprint_a}, #{String.downcase(@fingerprint_b)}")

      conn = get(conn, "/.well-known/assetlinks.json")

      assert ["application/json" <> _] = get_resp_header(conn, "content-type")
      assert get_resp_header(conn, "set-cookie") == []

      statements = json_response(conn, 200)

      assert Enum.map(statements, & &1["target"]["package_name"]) ==
               ["co.eyra.next", "co.eyra.next.dev", "co.eyra.next.staging"]

      for statement <- statements do
        assert statement["relation"] == ["delegate_permission/common.handle_all_urls"]
        assert statement["target"]["namespace"] == "android_app"
        assert statement["target"]["sha256_cert_fingerprints"] == [@fingerprint_a, @fingerprint_b]
      end
    end

    test "drops malformed fingerprints", %{conn: conn} do
      put_fingerprints("AB:CD\n#{@fingerprint_a} #{@fingerprint_a}:AB,#{@fingerprint_b}x")

      assert [%{"target" => %{"sha256_cert_fingerprints" => [@fingerprint_a]}} | _] =
               conn |> get("/.well-known/assetlinks.json") |> json_response(200)
    end

    test "is not found without a well-formed fingerprint", %{conn: conn} do
      assert conn |> get("/.well-known/assetlinks.json") |> response(404) == ""

      put_fingerprints("nonsense")
      assert conn |> get("/.well-known/assetlinks.json") |> response(404) == ""
    end
  end

  defp put_fingerprints(value) do
    Mica.Env.put(:android_app_cert_fingerprints, value)
    on_exit(fn -> Application.delete_env(:mica, :android_app_cert_fingerprints) end)
  end
end
