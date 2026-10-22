defmodule Systems.Rate.ServerTest do
  use ExUnit.Case, async: true

  alias Systems.Rate.Server

  @otp_request [service: :otp_request, limit: 3, unit: :call, window: :minute, scope: :local]
  @signup [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local]

  describe "init/1" do
    test "keeps the default quota of a service the overrides don't list" do
      {:ok, state} =
        Server.init(
          quotas: [@otp_request],
          quota_overrides: [
            %{
              "service" => "signup",
              "limit" => 10,
              "unit" => "call",
              "window" => "minute",
              "scope" => "local"
            }
          ]
        )

      assert Enum.map(state.quotas, &{&1.service, &1.limit}) == [
               {"otp_request", 3},
               {"signup", 10}
             ]
    end

    test "replaces the default quota of a service the overrides list" do
      {:ok, state} =
        Server.init(
          quotas: [@otp_request, @signup],
          quota_overrides: [Keyword.put(@signup, :limit, 1)]
        )

      assert Enum.map(state.quotas, &{&1.service, &1.limit}) == [
               {"otp_request", 3},
               {"signup", 1}
             ]
    end

    test "uses the default quotas without overrides" do
      {:ok, state} = Server.init(quotas: [@otp_request, @signup])

      assert Enum.map(state.quotas, & &1.service) == ["otp_request", "signup"]
    end
  end
end
