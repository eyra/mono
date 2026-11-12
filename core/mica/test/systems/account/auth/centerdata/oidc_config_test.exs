defmodule Systems.Account.Auth.Centerdata.OIDCConfigTest do
  # Captures the global stderr, so it can't run alongside other tests.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "Assent accepts the configured client authentication method without a warning" do
    config =
      Application.fetch_env!(:mica, Systems.Account.Auth.Centerdata)
      |> Keyword.merge(
        openid_configuration: %{"token_endpoint" => "https://messpanel.test/token"},
        session_params: %{state: "expected-state"}
      )

    warnings =
      capture_io(:stderr, fn ->
        assert {:error, _} = Assent.Strategy.OIDC.callback(config, %{"state" => "other-state"})
      end)

    assert warnings == ""
  end
end
