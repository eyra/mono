defmodule Systems.Storage.PublicAddressTest do
  # Mocks the URL check.
  use ExUnit.Case, async: false

  import Mock

  @moduletag :capture_log

  alias Frameworks.Utility.OutboundUrl
  alias Systems.Storage.Azure
  alias Systems.Storage.Yoda

  @identifier %{"identifier" => [[:assignment, 1], [:participant, "abc"]]}

  @refused_yoda_urls [
    "https://127.0.0.1/research-group/folder",
    "https://10.1.2.3/research-group/folder",
    "https://169.254.169.254/latest/meta-data",
    "https://100.100.100.200/latest/meta-data",
    "https://[::1]/research-group/folder",
    "https://[fd00:ec2::254]/latest/meta-data",
    "https://localhost/research-group/folder",
    "https://1.1.1.1:8443/research-group/folder",
    "http://1.1.1.1/research-group/folder",
    "http+unix://%2Ftmp%2Fnext.sock/folder"
  ]

  # The host is "#{account_name}.blob.core.windows.net", so these would send
  # the donation to the address in front of the slash, question mark or hash.
  @refused_azure_account_names [
    "127.0.0.1/",
    "10.1.2.3?",
    "169.254.169.254#",
    "[::1]/",
    "localhost:8080/",
    "user@127.0.0.1/",
    "panel.example/"
  ]

  @local_yoda_urls [
    "https://127.0.0.1:{port}/folder",
    "https://localhost:{port}/folder",
    "http://localhost:{port}/folder"
  ]

  describe "saving a Yoda endpoint" do
    for url <- @refused_yoda_urls do
      test "refuses the url #{url}" do
        changeset = Yoda.EndpointModel.changeset(%Yoda.EndpointModel{}, %{url: unquote(url)})
        refute changeset.valid?
        assert [url: {message, []}] = changeset.errors
        assert is_binary(message)
      end
    end

    test "gives a name that doesn't resolve the same answer as a private address" do
      unknown =
        Yoda.EndpointModel.changeset(%Yoda.EndpointModel{}, %{url: "https://next-t0288.invalid/f"})

      private = Yoda.EndpointModel.changeset(%Yoda.EndpointModel{}, %{url: "https://10.1.2.3/f"})

      assert unknown.errors == private.errors
    end

    test "accepts a public https url" do
      changeset =
        Yoda.EndpointModel.changeset(%Yoda.EndpointModel{}, %{
          url: "https://1.1.1.1/research-group/folder",
          user: "researcher",
          password: "secret"
        })

      assert changeset.valid?
    end
  end

  describe "saving an Azure endpoint" do
    for account_name <- @refused_azure_account_names do
      test "refuses the account name #{account_name}" do
        changeset =
          Azure.EndpointModel.changeset(%Azure.EndpointModel{}, %{
            account_name: unquote(account_name)
          })

        refute changeset.valid?
        assert [account_name: {message, _}] = changeset.errors
        assert is_binary(message)
      end
    end

    test "accepts a storage account name" do
      changeset =
        Azure.EndpointModel.changeset(%Azure.EndpointModel{}, %{
          account_name: "researchdata01",
          container: "donations",
          sas_token: "?sv=1&sig=s"
        })

      assert changeset.valid?
    end
  end

  describe "sending to a Yoda endpoint" do
    for url <- @local_yoda_urls do
      test "doesn't store the file on the local server at #{url}" do
        endpoint = yoda_endpoint(local_url(unquote(url)))

        assert {:error, _} = Yoda.Backend.store(endpoint, "{}", @identifier)
        refute_received {:accepted, _}
      end

      test "doesn't test the connection to the local server at #{url}" do
        endpoint = %{user: "researcher", password: "secret", url: local_url(unquote(url))}

        refute Yoda.Backend.connected?(endpoint)
        refute_received {:accepted, _}
      end
    end

    test "doesn't store the file at the metadata address" do
      endpoint = yoda_endpoint("https://169.254.169.254/latest/meta-data")

      assert {:error, :address_not_allowed} = Yoda.Backend.store(endpoint, "{}", @identifier)
    end

    test "stores the file at a public endpoint" do
      with_mock OutboundUrl, [:passthrough],
        request: fn _, _, _, _, _ -> {:ok, 201, [], ""} end do
        endpoint = yoda_endpoint("https://yoda.example/research-group/folder")

        assert :ok = Yoda.Backend.store(endpoint, "{}", @identifier)

        assert_called(
          OutboundUrl.request(
            :put,
            "https://yoda.example/research-group/folder/assignment=1_participant=abc.json",
            :_,
            "{}",
            :_
          )
        )
      end
    end

    test "tests the connection to a public endpoint" do
      with_mock OutboundUrl, [:passthrough], request: fn _, _, _, _, _ -> {:ok, 200, []} end do
        endpoint = %{user: "researcher", password: "secret", url: "https://yoda.example/folder"}

        assert Yoda.Backend.connected?(endpoint)
        assert_called(OutboundUrl.request(:head, "https://yoda.example/folder", :_, :_, :_))
      end
    end
  end

  describe "sending to an Azure endpoint" do
    test "doesn't store the file on the local server" do
      endpoint = azure_endpoint("127.0.0.1:#{listen()}/")

      assert {:error, _} = Azure.Backend.store(endpoint, "{}", @identifier)
      refute_received {:accepted, _}
    end

    test "doesn't store the file at the metadata address" do
      endpoint = azure_endpoint("169.254.169.254/")

      assert {:error, _} = Azure.Backend.store(endpoint, "{}", @identifier)
    end

    test "stores the file in a storage account" do
      with_mock OutboundUrl, [:passthrough],
        request: fn _, _, _, _, _ -> {:ok, 201, [], ""} end do
        endpoint = azure_endpoint("researchdata01")

        assert :ok = Azure.Backend.store(endpoint, "{}", @identifier)

        assert_called(
          OutboundUrl.request(
            :put,
            "https://researchdata01.blob.core.windows.net/donations/assignment=1_participant=abc.json?sv=1&sig=s",
            :_,
            "{}",
            :_
          )
        )
      end
    end
  end

  defp yoda_endpoint(url), do: %{"user" => "researcher", "password" => "secret", "url" => url}

  defp azure_endpoint(account_name) do
    %{"account_name" => account_name, "container" => "donations", "sas_token" => "?sv=1&sig=s"}
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
