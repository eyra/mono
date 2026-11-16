defmodule MicaWeb.FeatureCaseTest do
  use ExUnit.Case, async: false

  alias MicaWeb.FeatureCase

  @binary "/opt/chrome-for-testing/chrome"

  setup do
    chromedriver = Application.get_env(:wallaby, :chromedriver)
    on_exit(fn -> Application.put_env(:wallaby, :chromedriver, chromedriver) end)
    Application.put_env(:wallaby, :chromedriver, [])

    %{bypass: Bypass.open()}
  end

  describe "chrome_capabilities/1" do
    test "adds the configured Chrome binary" do
      Application.put_env(:wallaby, :chromedriver, binary: @binary)

      assert FeatureCase.chrome_capabilities(%{args: ["--lang=nl-NL"]}) ==
               %{chromeOptions: %{args: ["--lang=nl-NL"], binary: @binary}}
    end

    test "leaves the binary to chromedriver when none is configured" do
      assert FeatureCase.chrome_capabilities(%{args: ["--lang=nl-NL"]}) ==
               %{chromeOptions: %{args: ["--lang=nl-NL"]}}
    end
  end

  describe "create_session/2" do
    test "raises chromedriver's reason when it refuses the session", %{bypass: bypass} do
      chromedriver_responds(bypass, %{
        sessionId: "0f50e075",
        status: 33,
        value: %{
          message:
            "session not created: This version of ChromeDriver only supports Chrome version 155"
        }
      })

      assert_raise RuntimeError, ~r/only supports Chrome version 155/, fn ->
        FeatureCase.create_session(base_url(bypass), %{chromeOptions: %{args: []}})
      end
    end

    test "returns the session chromedriver started", %{bypass: bypass} do
      chromedriver_responds(bypass, %{sessionId: "0f50e075", status: 0, value: %{}})

      assert {:ok, %{"sessionId" => "0f50e075"}} =
               FeatureCase.create_session(base_url(bypass), %{chromeOptions: %{args: []}})
    end

    test "refuses capabilities without the configured binary", %{bypass: bypass} do
      Application.put_env(:wallaby, :chromedriver, binary: @binary)

      assert_raise RuntimeError, ~r/chrome_capabilities/, fn ->
        FeatureCase.create_session(base_url(bypass), %{chromeOptions: %{args: []}})
      end
    end
  end

  defp chromedriver_responds(bypass, body) do
    Bypass.expect_once(bypass, "POST", "/session", &Plug.Conn.resp(&1, 200, Jason.encode!(body)))
  end

  defp base_url(%Bypass{port: port}), do: "http://localhost:#{port}/"
end
