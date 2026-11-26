defmodule Next.Systems.WellKnown.ControllerTest do
  # Not async: the assetlinks tests change the application config.
  use NextWeb.ConnCase, async: false

  @fingerprint_a Enum.map_join(1..32, ":", fn _ -> "AB" end)
  @fingerprint_b Enum.map_join(1..32, ":", fn _ -> "0F" end)

  alias Systems.Affiliate
  alias Systems.Assignment

  test "serves the apple-app-site-association as JSON without a redirect or session", %{
    conn: conn
  } do
    conn = get(conn, "/.well-known/apple-app-site-association")

    assert ["application/json" <> _] = get_resp_header(conn, "content-type")
    assert get_resp_header(conn, "set-cookie") == []

    assert %{"applinks" => %{"details" => [%{"appIDs" => app_ids}]}} = json_response(conn, 200)

    assert "XNWQJGGM96.co.eyra.next" in app_ids
    assert "XNWQJGGM96.co.eyra.next.dev" in app_ids
  end

  # The panel participant is signed in in the browser the panel link opened in; the
  # app would open their study as its own user and get a 403 (Flux 10431393446).
  test "the app opens invitation links, but not the study a panel link signed the browser in for",
       %{conn: conn} do
    %{id: id} = assignment = Assignment.Factories.create_assignment_with_affiliate()
    %URI{path: entry} = URI.parse(Affiliate.Public.url_for_resource(assignment))
    landing = conn |> get("#{entry}?p=panel-1") |> redirected_to()

    components = app_link_components(NextWeb.ConnCase.build_conn())

    refute claimed?(components, landing)
    assert claimed?(components, "/assignment/#{id}")
    assert claimed?(components, "/assignment/#{id}/invite")
  end

  # A panel participant returns from an external survey here in the browser they are
  # signed in in; in the app the task wouldn't be marked done (Flux 10541358390).
  test "the app leaves the survey return link to the browser" do
    components = app_link_components(NextWeb.ConnCase.build_conn())

    refute claimed?(components, "/assignment/callback/7")
    refute claimed?(components, "/assignment/callback/7?p=panel-1")
    assert claimed?(components, "/assignment/7")
  end

  defp app_link_components(conn) do
    %{"applinks" => %{"details" => [%{"components" => components}]}} =
      conn |> get("/.well-known/apple-app-site-association") |> json_response(200)

    components
  end

  # iOS's rule: the first component whose path and query match decides.
  defp claimed?(components, link) do
    %URI{path: path, query: query} = URI.parse(link)
    params = URI.decode_query(query || "")

    case Enum.find(
           components,
           &(path_matches?(&1["/"], path) and query_matches?(&1["?"], params))
         ) do
      nil -> false
      component -> not Map.get(component, "exclude", false)
    end
  end

  defp path_matches?(pattern, path),
    do: String.starts_with?(path, String.trim_trailing(pattern, "*"))

  defp query_matches?(nil, _params), do: true

  defp query_matches?(query, params),
    do: Enum.all?(query, fn {key, value} -> params[key] == value end)

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
