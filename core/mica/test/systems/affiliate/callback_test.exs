defmodule Systems.Affiliate.CallbackTest do
  # Sets the global :affiliate_callback limits and mocks the URL check.
  use ExUnit.Case, async: false

  import Mock

  @moduletag :capture_log

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Affiliate

  # These tests are about the connection to the local servers they start, which
  # the URL check refuses.
  setup_with_mocks([
    {OutboundUrl, [:passthrough], [request: &:hackney.request/5]}
  ]) do
    :ok
  end

  setup do
    initial_limits = Application.get_env(:mica, :affiliate_callback)

    on_exit(fn ->
      if initial_limits,
        do: Application.put_env(:mica, :affiliate_callback, initial_limits),
        else: Application.delete_env(:mica, :affiliate_callback)
    end)
  end

  describe "callback/1" do
    test "returns the status" do
      bypass = Bypass.open()

      Bypass.expect_once(bypass, "GET", "/callback", fn conn ->
        Plug.Conn.resp(conn, 200, "ok")
      end)

      assert {:ok, 200} = Affiliate.Private.callback("http://localhost:#{bypass.port}/callback")
    end

    test "returns at the status and closes a large body unread" do
      url = serve_once(&send_body(&1, :binary.copy("x", 65_536), 10))

      assert {:ok, 200} = timed_callback(url, 1_000)
      assert_receive {:served, :client_closed}, 1_000
    end

    test "returns at the status and closes a slow body unread" do
      url = serve_once(&send_body(&1, "x", 100))

      assert {:ok, 200} = timed_callback(url, 1_000)
      assert_receive {:served, :client_closed}, 1_000
    end

    test "gives up at the deadline when the status is slow" do
      Application.put_env(:mica, :affiliate_callback, deadline: 300)

      url =
        serve_once(fn socket ->
          Process.sleep(1_500)
          :gen_tcp.send(socket, "HTTP/1.1 200 OK\r\ncontent-length: 0\r\n\r\n")
        end)

      assert {:error, :deadline_exceeded} = timed_callback(url, 1_000)
    end

    test "gives up at the deadline when the headers are slow" do
      Application.put_env(:mica, :affiliate_callback, deadline: 300)
      url = serve_once(&send_headers_slowly/1)

      assert {:error, :deadline_exceeded} = timed_callback(url, 700)
      assert_receive {:served, :client_closed}, 1_000
      refute_received {:hackney_response, _, _}
    end

    test "stops the connection when the request fails after connecting" do
      url = reset_on_accept()

      assert {:error, _reason} = Affiliate.Private.callback(url)
      assert own_connections() == []
    end

    test "kills the connection when stopping it raises" do
      url = serve_once(&:gen_tcp.send(&1, "HTTP/1.1 200 OK\r\ncontent-length: 0\r\n\r\n"))
      test = self()

      with_mock :hackney_conn, [:passthrough],
        stop: fn connection, timeout ->
          if self() == test,
            do: :erlang.error(:timeout_value),
            else: passthrough([connection, timeout])
        end do
        assert {:ok, 200} = Affiliate.Private.callback(url)
      end

      assert own_connections() == []
    end
  end

  # A hackney connection monitors the process that owns it. Waits up to 500 ms
  # for one that is being killed.
  defp own_connections(attempts \\ 10) do
    {:monitored_by, monitors} = Process.info(self(), :monitored_by)

    case Enum.filter(monitors, &hackney_connection?/1) do
      [_ | _] when attempts > 0 ->
        Process.sleep(50)
        own_connections(attempts - 1)

      connections ->
        connections
    end
  end

  defp hackney_connection?(pid) when is_pid(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dictionary} -> match?({:hackney_conn, _, _}, dictionary[:"$initial_call"])
      nil -> false
    end
  end

  defp hackney_connection?(_port_or_resource), do: false

  defp timed_callback(url, max_ms) do
    {elapsed_us, result} = :timer.tc(fn -> Affiliate.Private.callback(url) end)
    assert elapsed_us < max_ms * 1_000
    result
  end

  # One-request HTTP server: Bypass's Cowboy can't tell a handler that the
  # client went away, and these tests are about the client going away.
  defp serve_once(respond) do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false])
    {:ok, port} = :inet.port(listen)
    test = self()

    spawn_link(fn ->
      {:ok, socket} = :gen_tcp.accept(listen)
      {:ok, _request} = :gen_tcp.recv(socket, 0)
      send(test, {:served, respond.(socket)})
      :gen_tcp.close(socket)
    end)

    "http://localhost:#{port}/callback"
  end

  # Resets every connection as soon as it's accepted, before the request
  # arrives.
  defp reset_on_accept do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false])
    {:ok, port} = :inet.port(listen)

    spawn_link(fn -> reset_connections(listen) end)

    "http://localhost:#{port}/callback"
  end

  defp reset_connections(listen) do
    {:ok, socket} = :gen_tcp.accept(listen)
    :ok = :inet.setopts(socket, linger: {true, 0})
    :gen_tcp.close(socket)
    reset_connections(listen)
  end

  # Announces a 100 MiB body and sends `chunk` every `interval` ms for up to
  # 3 s, or until the client closes the connection.
  defp send_body(socket, chunk, interval) do
    :ok = :gen_tcp.send(socket, "HTTP/1.1 200 OK\r\ncontent-length: 104857600\r\n\r\n")
    send_chunks(socket, chunk, interval, System.monotonic_time(:millisecond) + 3_000)
  end

  # A status line, then one header line every 100 ms for up to 3 s.
  defp send_headers_slowly(socket) do
    :ok = :gen_tcp.send(socket, "HTTP/1.1 200 OK\r\n")
    send_chunks(socket, "x-pad: a\r\n", 100, System.monotonic_time(:millisecond) + 3_000)
  end

  defp send_chunks(socket, chunk, interval, stop_at) do
    Process.sleep(interval)

    cond do
      :gen_tcp.send(socket, chunk) != :ok -> :client_closed
      System.monotonic_time(:millisecond) > stop_at -> :all_sent
      true -> send_chunks(socket, chunk, interval, stop_at)
    end
  end
end
