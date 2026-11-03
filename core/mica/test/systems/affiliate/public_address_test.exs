defmodule Systems.Affiliate.PublicAddressTest do
  # Sets the global :affiliate_callback limits.
  use ExUnit.Case, async: false

  @moduletag :capture_log

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

    for url <- @unroutable_urls do
      test "doesn't call back #{url}" do
        assert {:error, :address_not_allowed} =
                 Affiliate.Private.callback(%{callback_url: unquote(url)}, nil, %{})
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
