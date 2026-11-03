defmodule Frameworks.Utility.OutboundUrlTest do
  # Mocks :hackney.
  use ExUnit.Case, async: false

  import Mock

  alias Frameworks.Utility.OutboundUrl

  @private_addresses [
    {0, 0, 0, 0},
    {10, 1, 2, 3},
    {100, 64, 0, 1},
    {100, 100, 100, 200},
    {127, 0, 0, 1},
    {169, 254, 169, 254},
    {172, 16, 0, 1},
    {172, 31, 255, 255},
    {192, 0, 0, 192},
    {192, 168, 1, 1},
    {198, 18, 0, 1},
    {224, 0, 0, 1},
    {255, 255, 255, 255},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 1},
    {0, 0, 0, 0, 0, 0xFFFF, 0x7F00, 1},
    {0, 0, 0, 0, 0, 0xFFFF, 0xA9FE, 0xA9FE},
    {0x64, 0xFF9B, 0, 0, 0, 0, 0x0A00, 1},
    {0x2002, 0xC0A8, 0x0101, 0, 0, 0, 0, 1},
    {0x2001, 0, 0x4136, 0xE378, 0x8000, 0x63BF, 0x3FFF, 0xFDD2},
    {0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1},
    {0xFC00, 0, 0, 0, 0, 0, 0, 1},
    {0xFD00, 0x0EC2, 0, 0, 0, 0, 0, 0x0254},
    {0xFE80, 0, 0, 0, 0, 0, 0, 1},
    {0xFF02, 0, 0, 0, 0, 0, 0, 1}
  ]

  @public_addresses [
    {1, 1, 1, 1},
    {93, 184, 215, 14},
    {172, 32, 0, 1},
    {0, 0, 0, 0, 0, 0xFFFF, 0x0101, 0x0101},
    {0x2002, 0x0101, 0x0101, 0, 0, 0, 0, 1},
    {0x2606, 0x4700, 0x4700, 0, 0, 0, 0, 0x1111}
  ]

  @refused_schemes [
    "http://example.org/",
    "ws://example.org/",
    "wss://example.org/",
    "ftp://example.org/",
    "http+unix://%2Ftmp%2Fnext.sock/",
    "example.org/callback"
  ]

  describe "public_address?/1" do
    for address <- @private_addresses do
      test "refuses #{:inet.ntoa(address)}" do
        refute OutboundUrl.public_address?(unquote(Macro.escape(address)))
      end
    end

    for address <- @public_addresses do
      test "allows #{:inet.ntoa(address)}" do
        assert OutboundUrl.public_address?(unquote(Macro.escape(address)))
      end
    end
  end

  describe "check/2" do
    for url <- @refused_schemes do
      test "refuses #{url}" do
        assert {:error, :scheme_not_allowed} = OutboundUrl.check(unquote(url), resolver: public())
      end
    end

    test "refuses a name with any private address" do
      resolver = fn "panel.example" -> {:ok, [{93, 184, 215, 14}, {10, 0, 0, 1}]} end

      assert {:error, :address_not_allowed} =
               OutboundUrl.check("https://panel.example/", resolver: resolver)
    end

    test "refuses a name that resolves to loopback" do
      assert {:error, :address_not_allowed} = OutboundUrl.check("https://localhost/")
    end

    test "refuses a name that doesn't resolve" do
      resolver = fn _host -> {:error, :host_not_found} end

      assert {:error, :host_not_found} =
               OutboundUrl.check("https://panel.example/", resolver: resolver)
    end

    test "refuses a port other than 443" do
      assert {:error, :port_not_allowed} =
               OutboundUrl.check("https://panel.example:8443/", resolver: public())
    end

    test "allows port 443 written out" do
      assert {:ok, _uri, _address} =
               OutboundUrl.check("https://panel.example:443/", resolver: public())
    end

    test "prefers an IPv4 address" do
      resolver = fn _host ->
        {:ok, [{0x2606, 0x4700, 0, 0, 0, 0, 0, 1}, {93, 184, 215, 14}]}
      end

      assert {:ok, %URI{host: "panel.example"}, {93, 184, 215, 14}} =
               OutboundUrl.check("https://panel.example/", resolver: resolver)
    end
  end

  describe "request/5" do
    test "connects to the checked address, with the host name for HTTP and TLS" do
      with_mock :hackney, request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        assert {:ok, 200, []} =
                 OutboundUrl.request(:head, "https://panel.example/return?panel=1", [], "",
                   connect_timeout: 1_000,
                   resolver: public()
                 )

        assert_called(
          :hackney.request(
            :head,
            "https://93.184.215.14/return?panel=1",
            [{"host", "panel.example"}],
            "",
            :_
          )
        )

        [{_pid, {:hackney, :request, [_, _, _, _, options]}, _result}] =
          call_history(:hackney)

        assert options[:connect_timeout] == 1_000
        assert options[:follow_redirect] == false
        assert options[:protocols] == [:http1]
        assert options[:ssl_options] == [server_name_indication: ~c"panel.example"]
        refute Keyword.has_key?(options, :resolver)
      end
    end

    test "gives up at the deadline when the DNS lookup is slow" do
      # Slower than the deadline but faster than the 5 s default, so a lookup
      # the deadline doesn't bound finishes and refuses the private address.
      resolver = fn _host ->
        Process.sleep(2_500)
        {:ok, [{10, 0, 0, 1}]}
      end

      with_mock :hackney, request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        links = links()

        assert {:error, :timeout} =
                 OutboundUrl.request(:get, "https://panel.example/", [], "",
                   deadline: 300,
                   resolver: resolver
                 )

        assert links() == links, "the DNS lookup is still running"
        assert_not_called(:hackney.request(:_, :_, :_, :_, :_))
      end
    end

    test "connects within what the DNS lookup left of the deadline" do
      resolver = fn _host ->
        Process.sleep(200)
        {:ok, [{93, 184, 215, 14}]}
      end

      with_mock :hackney, request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        OutboundUrl.request(:get, "https://panel.example/", [], "",
          connect_timeout: 5_000,
          deadline: 1_000,
          resolver: resolver
        )

        [{_pid, {:hackney, :request, [_, _, _, _, options]}, _result}] = call_history(:hackney)
        assert options[:connect_timeout] <= 800
        refute Keyword.has_key?(options, :deadline)
      end
    end

    test "connects to an IPv6 address in brackets" do
      resolver = fn _host -> {:ok, [{0x2606, 0x4700, 0, 0, 0, 0, 0, 1}]} end

      with_mock :hackney, request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        OutboundUrl.request(:get, "https://panel.example/cb", [], "", resolver: resolver)

        assert_called(:hackney.request(:get, "https://[2606:4700::1]/cb", :_, "", :_))
      end
    end

    test "resolves again and refuses a name that now resolves to a private address" do
      {:ok, rebinding} = Agent.start_link(fn -> [{93, 184, 215, 14}, {169, 254, 169, 254}] end)

      resolver = fn _host ->
        {:ok, [Agent.get_and_update(rebinding, fn [next | rest] -> {next, rest} end)]}
      end

      assert {:ok, _uri, _address} =
               OutboundUrl.check("https://panel.example/", resolver: resolver)

      with_mock :hackney, request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        assert {:error, :address_not_allowed} =
                 OutboundUrl.request(:get, "https://panel.example/", [], "", resolver: resolver)

        assert_not_called(:hackney.request(:_, :_, :_, :_, :_))
      end
    end
  end

  defp public, do: fn _host -> {:ok, [{93, 184, 215, 14}]} end

  # The DNS lookup runs in a task linked to the caller.
  defp links do
    {:links, links} = Process.info(self(), :links)
    Enum.sort(links)
  end
end
