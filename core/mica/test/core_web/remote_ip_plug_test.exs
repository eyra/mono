defmodule CoreWeb.Plug.RemoteIpTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias CoreWeb.Plug.RemoteIp

  defp call(peer, headers) do
    conn(:get, "/")
    |> Map.put(:remote_ip, peer)
    |> then(&Enum.reduce(headers, &1, fn {k, v}, conn -> put_req_header(conn, k, v) end))
    |> init_test_session(%{})
    |> RemoteIp.call([])
  end

  describe "a request through a proxy" do
    test "comes from the address the proxy put in X-Forwarded-For" do
      conn = call({127, 0, 0, 1}, [{"x-forwarded-for", "203.0.113.10"}])

      assert conn.remote_ip == {203, 0, 113, 10}
      assert get_session(conn, :remote_ip) == "203.0.113.10"
    end

    test "comes from the last public address when the proxy appends to X-Forwarded-For" do
      conn = call({172, 16, 0, 5}, [{"x-forwarded-for", "198.51.100.1, 203.0.113.10, 10.0.0.2"}])

      assert conn.remote_ip == {203, 0, 113, 10}
    end

    test "ignores forwarding headers a proxy passes on unchanged" do
      headers = [
        {"x-forwarded-for", "203.0.113.10"},
        {"x-client-ip", "198.51.100.1"},
        {"x-real-ip", "198.51.100.2"},
        {"forwarded", "for=198.51.100.3"}
      ]

      assert call({127, 0, 0, 1}, headers).remote_ip == {203, 0, 113, 10}
      assert call({127, 0, 0, 1}, tl(headers)).remote_ip == {127, 0, 0, 1}
    end

    test "comes from an IPv6 address" do
      conn = call({0xFDAA, 0, 0, 0, 0, 0, 0, 1}, [{"x-forwarded-for", "2001:db8::1"}])

      assert get_session(conn, :remote_ip) == "2001:db8::1"
    end
  end

  test "a request from a public address keeps that address" do
    conn = call({203, 0, 113, 10}, [{"x-forwarded-for", "198.51.100.1"}])

    assert conn.remote_ip == {203, 0, 113, 10}
    assert get_session(conn, :remote_ip) == "203.0.113.10"
  end
end
