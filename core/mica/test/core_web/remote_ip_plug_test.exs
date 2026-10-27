defmodule CoreWeb.Plug.RemoteIpTest do
  # Some tests set the trusted proxies in the application environment.
  use ExUnit.Case, async: false

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

  defp trust(proxies) do
    original = Core.Env.get(RemoteIp)
    Core.Env.put(RemoteIp, trusted_proxies: proxies)

    on_exit(fn ->
      if original,
        do: Core.Env.put(RemoteIp, original),
        else: Application.delete_env(:core, RemoteIp)
    end)
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

  test "the client's address is in the Logger metadata" do
    call({127, 0, 0, 1}, [{"x-forwarded-for", "203.0.113.10"}])

    assert Logger.metadata()[:remote_ip] == "203.0.113.10"
  end

  describe "configured trusted proxies" do
    test "a request from a listed public proxy comes from X-Forwarded-For" do
      trust(["198.51.100.0/24"])

      assert call({198, 51, 100, 7}, [{"x-forwarded-for", "203.0.113.10"}]).remote_ip ==
               {203, 0, 113, 10}
    end

    test "a listed proxy in X-Forwarded-For is skipped" do
      trust(["127.0.0.1", "198.51.100.0/24"])

      conn = call({127, 0, 0, 1}, [{"x-forwarded-for", "203.0.113.10, 198.51.100.7"}])

      assert conn.remote_ip == {203, 0, 113, 10}
    end

    test "replace the default ranges" do
      trust(["198.51.100.0/24"])

      assert call({127, 0, 0, 1}, [{"x-forwarded-for", "203.0.113.10"}]).remote_ip ==
               {127, 0, 0, 1}
    end

    test "take IPv6 ranges" do
      trust(["2001:db8:aa::/48"])

      assert call({0x2001, 0xDB8, 0xAA, 0, 0, 0, 0, 9}, [{"x-forwarded-for", "203.0.113.10"}]).remote_ip ==
               {203, 0, 113, 10}
    end
  end

  describe "trusted_proxies!/1" do
    test "accepts addresses and CIDR ranges" do
      proxies = ["127.0.0.1", "10.0.0.0/8", "::1", "2001:db8::/32"]

      assert RemoteIp.trusted_proxies!(proxies) == proxies
    end

    test "raises on an entry that isn't an address" do
      assert_raise ArgumentError, fn -> RemoteIp.trusted_proxies!(["proxy.example.com"]) end
    end

    test "raises on a prefix longer than the address" do
      assert_raise ArgumentError, fn -> RemoteIp.trusted_proxies!(["10.0.0.0/33"]) end
    end
  end
end
