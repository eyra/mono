defmodule Mica.OutboundHttpTest do
  use ExUnit.Case, async: true

  test "hackney negotiates HTTP/1.1 with a server that prefers HTTP/2" do
    {url, ssl_options} = serve_tls_once(["h2", "http/1.1"])

    assert {:ok, 200, _headers, ""} =
             :hackney.request(:get, url, [], "", ssl_options: ssl_options, pool: false)

    assert_receive {:negotiated, {:ok, "http/1.1"}}
  end

  defp serve_tls_once(alpn_protocols) do
    %{server_config: server_config, client_config: client_config} =
      :public_key.pkix_test_data(%{
        server_chain: %{root: rsa_key(), intermediates: [], peer: rsa_key()},
        client_chain: %{root: rsa_key(), intermediates: [], peer: rsa_key()}
      })

    {:ok, listen} =
      :ssl.listen(0, [alpn_preferred_protocols: alpn_protocols, active: false] ++ server_config)

    {:ok, {_address, port}} = :ssl.sockname(listen)
    test = self()

    spawn_link(fn ->
      {:ok, transport} = :ssl.transport_accept(listen)
      {:ok, socket} = :ssl.handshake(transport)
      negotiated = :ssl.negotiated_protocol(socket)
      send(test, {:negotiated, negotiated})
      respond(socket, negotiated)
    end)

    # The test certificate is issued to this machine's host name.
    ssl_options = [
      cacerts: Keyword.fetch!(client_config, :cacerts),
      server_name_indication: :net_adm.localhost()
    ]

    {"https://localhost:#{port}/", ssl_options}
  end

  defp rsa_key, do: [key: {:rsa, 2048, 65_537}]

  defp respond(socket, {:ok, "http/1.1"}) do
    {:ok, _request} = :ssl.recv(socket, 0)
    :ok = :ssl.send(socket, "HTTP/1.1 200 OK\r\ncontent-length: 0\r\n\r\n")
    :ssl.close(socket)
  end

  defp respond(socket, _other), do: :ssl.close(socket)
end
