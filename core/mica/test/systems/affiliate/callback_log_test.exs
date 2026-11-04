defmodule Systems.Affiliate.CallbackLogTest do
  # Mocks the URL check.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mock

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Affiliate

  @user_info %{info: ~s({"participant_id":"participant-4711"})}
  @event %{progress: "finished"}
  @secrets ["researcher", "s3cret", "api_token", "tok-9137", "participant-4711"]

  describe "callback/3 error log" do
    test "names the host and the reason of a refused address, not the query or user info" do
      affiliate = %{callback_url: "https://researcher:s3cret@127.0.0.1/cb?api_token=tok-9137"}

      log =
        capture_log(fn ->
          assert {:error, :address_not_allowed} =
                   Affiliate.Private.callback(affiliate, @user_info, @event)
        end)

      assert log =~ "127.0.0.1"
      assert log =~ "address_not_allowed"
      refute_secrets(log)
    end

    test "names the host and the reason of a failed request, not the query or user info" do
      port = closed_port()

      affiliate = %{
        callback_url: "http://researcher:s3cret@localhost:#{port}/cb?api_token=tok-9137"
      }

      log =
        with_mock OutboundUrl, [:passthrough], request: &:hackney.request/5 do
          capture_log(fn ->
            assert {:error, :econnrefused} =
                     Affiliate.Private.callback(affiliate, @user_info, @event)
          end)
        end

      assert log =~ "localhost"
      assert log =~ "econnrefused"
      refute_secrets(log)
    end

    test "names only the kind of an error reason that repeats the URL" do
      affiliate = %{callback_url: "https://researcher:s3cret@example.org/cb?api_token=tok-9137"}

      request = fn _method, url, _headers, _body, _options -> {:error, {:closed, url}} end

      log =
        with_mock OutboundUrl, [:passthrough], request: request do
          capture_log(fn ->
            assert {:error, {:closed, _url}} =
                     Affiliate.Private.callback(affiliate, @user_info, @event)
          end)
        end

      assert log =~ "example.org"
      assert log =~ "closed"
      refute_secrets(log)
    end
  end

  defp refute_secrets(log) do
    for secret <- @secrets, do: refute(log =~ secret, "log contains #{inspect(secret)}")
  end

  defp closed_port do
    {:ok, socket} = :gen_tcp.listen(0, [])
    {:ok, port} = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end
end
