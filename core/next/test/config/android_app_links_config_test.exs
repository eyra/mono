defmodule Next.Config.AndroidAppLinksConfigTest do
  # Replaces the process environment while runtime.exs is evaluated.
  use ExUnit.Case, async: false

  alias Mica.RuntimeConfig.Snapshot

  @fingerprint_a Enum.map_join(1..32, ":", fn _ -> "AB" end)
  @fingerprint_b Enum.map_join(1..32, ":", fn _ -> "0F" end)

  # The config runtime.exs gives a release for the prod fixture with `overrides` on top.
  defp release_config(overrides) do
    env =
      "next/test/config/env/prod.env"
      |> Snapshot.read_env_file()
      |> Map.merge(overrides)

    Snapshot.evaluate("config/runtime.exs", env, :prod)
  end

  test "without ANDROID_APP_CERT_FINGERPRINTS no Android app is configured" do
    assert release_config(%{})[:mica][:android_app_links] == nil
  end

  test "reads <package>=<fingerprint> entries, separated by commas or whitespace" do
    value = "co.eyra.next=#{String.downcase(@fingerprint_a)},\nco.eyra.next=#{@fingerprint_b}"

    assert release_config(%{"ANDROID_APP_CERT_FINGERPRINTS" => value})[:mica][:android_app_links] ==
             [{"co.eyra.next", @fingerprint_a}, {"co.eyra.next", @fingerprint_b}]
  end

  test "refuses a malformed entry, naming its position and not its value" do
    for bad <- [
          @fingerprint_a,
          "co.eyra.next=AB:CD",
          "co.eyra.next=#{String.replace(@fingerprint_a, ":", "")}",
          "next=#{@fingerprint_a}"
        ] do
      value = "co.eyra.next=#{@fingerprint_a} #{bad}"

      error =
        assert_raise RuntimeError, fn ->
          release_config(%{"ANDROID_APP_CERT_FINGERPRINTS" => value})
        end

      assert error.message =~ "ANDROID_APP_CERT_FINGERPRINTS: entry 2 is not"
      refute error.message =~ bad
    end
  end
end
