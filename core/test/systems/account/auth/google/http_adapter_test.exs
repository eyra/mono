defmodule Systems.Account.Auth.Google.HTTPAdapter.TestClient do
  def request(:get, "https://example.com/certs", nil, []) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       headers: [{"content-type", "application/json"}],
       body: "{}"
     }}
  end

  def request(:get, "https://example.com/unavailable", nil, []), do: {:error, :econnrefused}
end

defmodule Systems.Account.Auth.Google.HTTPAdapterTest do
  use ExUnit.Case, async: true

  alias Assent.HTTPAdapter.HTTPResponse
  alias Systems.Account.Auth.Google.HTTPAdapter

  @opts [http_client: Systems.Account.Auth.Google.HTTPAdapter.TestClient]

  test "converts HTTPoison responses for Assent" do
    assert {:ok,
            %HTTPResponse{
              status: 200,
              headers: [{"content-type", "application/json"}],
              body: "{}"
            }} =
             HTTPAdapter.request(:get, "https://example.com/certs", nil, [], @opts)
  end

  test "preserves HTTP client errors" do
    assert {:error, :econnrefused} =
             HTTPAdapter.request(:get, "https://example.com/unavailable", nil, [], @opts)
  end
end
