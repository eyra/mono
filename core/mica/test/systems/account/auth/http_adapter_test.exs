defmodule Systems.Account.Auth.HTTPAdapterTest do
  use ExUnit.Case, async: true

  setup do
    %{bypass: Bypass.open()}
  end

  test "passes the identity provider's response headers on", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/userinfo", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "text/plain")
      |> Plug.Conn.resp(200, "ok")
    end)

    assert {:ok, %{headers: headers}} =
             Assent.HTTPAdapter.request(:get, url(bypass, "/userinfo"), nil, [], [])

    assert {"content-type", "text/plain"} in headers
  end

  test "does not retry a failing identity provider", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/keys", &Plug.Conn.resp(&1, 503, ""))

    assert {:error, %{status: 503}} =
             Assent.HTTPAdapter.request(:get, url(bypass, "/keys"), nil, [], [])
  end

  defp url(%Bypass{port: port}, path), do: "http://localhost:#{port}#{path}"
end
