defmodule Systems.Affiliate.PublicAddressTest do
  # Sets the global :affiliate_callback limits and mocks the URL check.
  use ExUnit.Case, async: false

  import Mock

  @moduletag :capture_log

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Affiliate

  @refused_urls [
    "https://127.0.0.1/callback",
    "https://10.1.2.3/callback",
    "https://169.254.169.254/latest/meta-data/",
    "https://100.100.100.200/latest/meta-data/",
    "https://[::1]/callback",
    "https://[::ffff:127.0.0.1]/callback",
    "https://[fd00:ec2::254]/latest/meta-data/",
    "https://localhost/callback",
    "http+unix://%2Ftmp%2Fnext.sock/callback",
    "ws://example.org/callback",
    "http://example.org/callback"
  ]

  # Hosts `URI.new/1` accepts that aren't DNS names.
  @malformed_urls [
    "https://a..b/callback",
    "https://.example.org/callback",
    "https://example.org../callback",
    "https://#{String.duplicate("a", 64)}.example/callback",
    "https://#{String.duplicate("a.", 140)}org/callback"
  ]

  @unroutable_urls [
    "https://10.255.255.1/callback",
    "https://169.254.169.254/latest/meta-data/"
  ]

  @local_urls [
    "https://127.0.0.1:{port}/callback",
    "https://localhost:{port}/callback",
    "http://localhost:{port}/callback",
    "ws://localhost:{port}/callback"
  ]

  setup do
    initial_limits = Application.get_env(:mica, :affiliate_callback)
    Application.put_env(:mica, :affiliate_callback, connect_timeout: 300, deadline: 300)

    on_exit(fn ->
      if initial_limits,
        do: Application.put_env(:mica, :affiliate_callback, initial_limits),
        else: Application.delete_env(:mica, :affiliate_callback)
    end)
  end

  describe "saving" do
    for url <- @refused_urls do
      test "refuses the callback URL #{url}" do
        changeset = Affiliate.Model.changeset(%Affiliate.Model{}, %{callback_url: unquote(url)})
        refute changeset.valid?
      end

      test "refuses the redirect URL #{url}" do
        changeset = Affiliate.Model.changeset(%Affiliate.Model{}, %{redirect_url: unquote(url)})
        refute changeset.valid?
      end
    end

    test "refuses a port other than 443" do
      changeset =
        Affiliate.Model.changeset(%Affiliate.Model{}, %{
          callback_url: "https://1.1.1.1:22/callback"
        })

      refute changeset.valid?
    end

    # Otherwise the form tells which names the server's internal DNS knows.
    test "gives a name that doesn't resolve the same answer as a private address" do
      unknown =
        Affiliate.Model.changeset(%Affiliate.Model{}, %{
          callback_url: "https://next-t0275.invalid/callback"
        })

      private =
        Affiliate.Model.changeset(%Affiliate.Model{}, %{callback_url: "https://10.1.2.3/callback"})

      assert [callback_url: {message, []}] = private.errors
      assert unknown.errors == private.errors
      assert is_binary(message)
    end

    for url <- @malformed_urls do
      test "gives #{String.slice(url, 0, 40)} the same answer as a private address" do
        malformed = Affiliate.Model.changeset(%Affiliate.Model{}, %{callback_url: unquote(url)})

        private =
          Affiliate.Model.changeset(%Affiliate.Model{}, %{
            callback_url: "https://10.1.2.3/callback"
          })

        refute malformed.valid?
        assert malformed.errors == private.errors
      end
    end

    test "accepts a public https address" do
      changeset =
        Affiliate.Model.changeset(%Affiliate.Model{}, %{
          callback_url: "https://1.1.1.1/callback",
          redirect_url: "https://1.1.1.1/return?panel=1"
        })

      assert changeset.valid?
    end
  end

  describe "sending" do
    for url <- @local_urls do
      test "doesn't call back the local server at #{url}" do
        url = local_url(unquote(url))

        assert {:error, _} = Affiliate.Private.callback(%{callback_url: url}, nil, %{})
        refute_received {:accepted, _}
      end
    end

    for url <- @malformed_urls do
      test "doesn't call back #{String.slice(url, 0, 40)}" do
        assert {:error, :host_not_found} =
                 Affiliate.Private.callback(%{callback_url: unquote(url)}, nil, %{})
      end
    end

    for url <- @unroutable_urls do
      test "doesn't call back #{url}" do
        assert {:error, :address_not_allowed} =
                 Affiliate.Private.callback(%{callback_url: unquote(url)}, nil, %{})
      end
    end

    test "doesn't call back a port other than 443" do
      assert {:error, :port_not_allowed} =
               Affiliate.Private.callback(
                 %{callback_url: "https://1.1.1.1:8443/callback"},
                 nil,
                 %{}
               )
    end

    test "gives up at the deadline when the DNS lookup is slow" do
      slow_resolver = fn _host ->
        Process.sleep(1_000)
        {:ok, [{10, 0, 0, 1}]}
      end

      with_mock OutboundUrl, [:passthrough],
        request: fn method, url, headers, body, options ->
          passthrough([
            method,
            url,
            headers,
            body,
            Keyword.put(options, :resolver, slow_resolver)
          ])
        end do
        {elapsed_us, result} =
          :timer.tc(fn ->
            Affiliate.Private.callback(
              %{callback_url: "https://panel.example/callback"},
              nil,
              %{}
            )
          end)

        assert {:error, :timeout} = result
        assert elapsed_us < 600_000
      end
    end

    test "doesn't call back over a Unix socket" do
      assert {:error, :scheme_not_allowed} =
               Affiliate.Private.callback(
                 %{callback_url: "http+unix://%2Ftmp%2Fnext.sock/callback"},
                 nil,
                 %{}
               )
    end
  end

  describe "checking the URL" do
    for url <- @local_urls do
      test "doesn't request the local server at #{url}" do
        url = local_url(unquote(url))

        assert {:error, _} = Affiliate.Public.validate_url(url)
        refute_received {:accepted, _}
      end
    end

    for url <- @unroutable_urls do
      test "doesn't request #{url}" do
        assert {:error, :address_not_allowed} = Affiliate.Public.validate_url(unquote(url))
      end
    end

    for url <- @malformed_urls do
      test "doesn't request #{String.slice(url, 0, 40)}" do
        assert {:error, :host_not_found} = Affiliate.Public.validate_url(unquote(url))
      end
    end
  end

  defp local_url(template), do: String.replace(template, "{port}", to_string(listen()))

  # Accepts connections on 127.0.0.1 and reports each one to the test.
  defp listen do
    {:ok, listen} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, port} = :inet.port(listen)
    test = self()

    spawn_link(fn -> accept(listen, test) end)

    port
  end

  defp accept(listen, test) do
    {:ok, socket} = :gen_tcp.accept(listen)
    send(test, {:accepted, socket})
    :gen_tcp.close(socket)
    accept(listen, test)
  end
end
