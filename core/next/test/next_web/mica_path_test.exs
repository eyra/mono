defmodule NextWeb.MicaPathTest do
  # `~m` (MicaWeb.Path) must build exactly the paths `~p` built, for every form
  # Mica uses (code-compose PR 6).
  use ExUnit.Case, async: true

  use MicaWeb.Path

  use Phoenix.VerifiedRoutes,
    endpoint: MicaWeb.Endpoint,
    router: MicaWeb.Router,
    statics: MicaWeb.Path.statics()

  @assignment %Systems.Assignment.Model{id: 7}

  test "a static path" do
    assert ~m"/assignment/1" == ~p"/assignment/1"
    assert ~m"/" == ~p"/"
  end

  test "an interpolated segment, through Phoenix.Param and URI encoding" do
    assert ~m"/assignment/#{@assignment}" == "/assignment/7"
    assert ~m"/assignment/#{@assignment}" == ~p"/assignment/#{@assignment}"
    assert ~m"/assignment/#{42}/landing" == ~p"/assignment/#{42}/landing"
    assert ~m"/uploads/#{"a b/c é"}" == ~p"/uploads/#{"a b/c é"}"
  end

  test "a query from a keyword list or map" do
    params = [tab: "x y", page: 2, flag: true]
    assert ~m"/assignment/1?#{params}" == "/assignment/1?tab=x+y&page=2&flag=true"
    assert ~m"/assignment/1?#{params}" == ~p"/assignment/1?#{params}"

    assert ~m"/assignment/1?#{%{a: [1, 2], b: %{c: "d"}}}" ==
             ~p"/assignment/1?#{%{a: [1, 2], b: %{c: "d"}}}"

    assert ~m"/assignment/1?#{[]}" == ~p"/assignment/1?#{[]}"
  end

  test "static and interpolated query values" do
    query = "é&"
    assert ~m"/assignment/1?q=#{query}" == "/assignment/1?q=%C3%A9%26"
    assert ~m"/assignment/1?q=#{query}" == ~p"/assignment/1?q=#{query}"
    assert ~m"/assignment/1?a=#{1}&b=#{@assignment}" == ~p"/assignment/1?a=#{1}&b=#{@assignment}"
    assert ~m"/assignment/1?tab=items" == ~p"/assignment/1?tab=items"
    assert ~m"/assignment/1?tab=items&page=#{2}" == ~p"/assignment/1?tab=items&page=#{2}"
  end

  test "a fragment" do
    assert ~m"/assignment/1#top" == ~p"/assignment/1#top"
  end

  test "a static path goes through the endpoint's static_path/1" do
    icon = "logo"
    mica = ~m"/images/icons/#{"#{icon}.svg"}"
    phoenix = ~p"/images/icons/#{"#{icon}.svg"}"
    assert mica == phoenix
    assert ~m"/favicon.ico" == ~p"/favicon.ico"
  end

  test "url/2 for a socket and a conn" do
    socket = %Phoenix.LiveView.Socket{endpoint: MicaWeb.Endpoint}

    conn =
      Plug.Conn.put_private(Phoenix.ConnTest.build_conn(), :phoenix_endpoint, MicaWeb.Endpoint)

    token = "a/b c"

    for context <- [socket, conn] do
      assert MicaWeb.Path.url(context, ~m"/user/reset-password/#{token}") ==
               Phoenix.VerifiedRoutes.url(context, ~p"/user/reset-password/#{token}")
    end
  end

  test "segments encode like Phoenix's, lists included" do
    for data <- [[], ["a b", "c/d"], "é", 12, @assignment] do
      assert MicaWeb.Path.__encode_segment__(data) ==
               Phoenix.VerifiedRoutes.__encode_segment__(data)
    end
  end

  describe "the recorded paths" do
    defmodule Links do
      use MicaWeb.Path

      def page(id), do: ~m"/assignment/#{id}/landing?#{[tab: "x"]}"
      def icon, do: ~m"/images/icon.svg"
    end

    test "record every non-static path with its route, file and line" do
      assert [%{path: "/assignment/1/landing", route: route, file: file, line: line}] =
               Links.__mica_paths__()

      assert route == ~S|~m"/assignment/#{id}/landing?#{[tab: "x"]}"|
      assert file == __ENV__.file
      assert line == 75
    end
  end
end
