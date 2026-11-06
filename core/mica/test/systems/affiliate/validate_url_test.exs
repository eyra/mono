defmodule Systems.Affiliate.ValidateUrlTest do
  # Mocks the URL check.
  use ExUnit.Case, async: false

  import Mock

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Affiliate

  # These tests are about the response of the local server they start, which
  # the URL check refuses.
  setup_with_mocks([
    {OutboundUrl, [:passthrough], [request: &:hackney.request/5]}
  ]) do
    :ok
  end

  describe "validate_url/1" do
    test "returns the status of a 200" do
      url = serve_once("HTTP/1.1 200 OK\r\ncontent-length: 5\r\n\r\n")
      assert {:ok, 200} = Affiliate.Public.validate_url(url)
    end

    test "returns the status of a 301" do
      url = serve_once(redirect("301 Moved Permanently"))
      assert {:ok, 301} = Affiliate.Public.validate_url(url)
    end

    test "returns the status of a 302" do
      url = serve_once(redirect("302 Found"))
      assert {:ok, 302} = Affiliate.Public.validate_url(url)
    end

    test "returns the error for an unreachable URL" do
      {:ok, listen} = :gen_tcp.listen(0, [])
      {:ok, port} = :inet.port(listen)
      :ok = :gen_tcp.close(listen)

      assert {:error, :econnrefused} =
               Affiliate.Public.validate_url("http://localhost:#{port}/survey")
    end
  end

  defp redirect(status_line) do
    "HTTP/1.1 #{status_line}\r\nlocation: https://example.org/\r\ncontent-length: 0\r\n\r\n"
  end

  # One-request HTTP server that answers with `response`.
  defp serve_once(response) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false])
    {:ok, port} = :inet.port(listen)

    spawn_link(fn ->
      {:ok, socket} = :gen_tcp.accept(listen)
      {:ok, _request} = :gen_tcp.recv(socket, 0)
      :ok = :gen_tcp.send(socket, response)
      :gen_tcp.close(socket)
    end)

    "http://localhost:#{port}/survey"
  end
end
