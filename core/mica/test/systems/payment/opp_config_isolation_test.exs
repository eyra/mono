defmodule Systems.Payment.OPPConfigIsolationTest do
  @moduledoc """
  The OPP provider config is global, but async test modules run side by side.
  Two of them each saving and restoring the whole keyword list can interleave
  so that one puts back the other's override after the run moved on: the
  platform `merchant_uid` then stayed `"mer_platform"` for the sync modules that
  ran after them, failing `Systems.Payment.PublicTest` and
  `Systems.Fund.PublicTest` depending on the seed. A module that needs a
  different OPP config must be `async: false`.
  """
  use ExUnit.Case, async: true

  @core Path.expand("../../../..", __DIR__)
  @opp_write ~r/(Application\.(put_env|delete_env)\(\s*:mica,|Mica\.Env\.put\()\s*[\w.]*\bOPP\b/
  @async ~r/async:\s*true/
  @globs ["mica/test/**/*_test.exs", "next/test/**/*_test.exs", "mica_saas/test/**/*_test.exs"]
  # The sync OPP writers: if the scan no longer finds them, the globs have gone
  # stale and the guard would pass without checking anything.
  @known_sync_writers [
    "mica/test/systems/payment/opp_test.exs",
    "mica/test/systems/payment/partner_fee_test.exs"
  ]

  setup do
    files =
      @globs
      |> Enum.flat_map(&Path.wildcard(Path.join(@core, &1)))
      |> Enum.map(&Path.relative_to(&1, @core))

    %{files: files}
  end

  test "the scan covers the known sync OPP writers", %{files: files} do
    assert @known_sync_writers -- files == []
  end

  test "no async test module writes the OPP provider config", %{files: files} do
    assert Enum.filter(files, &async_opp_writer?/1) == []
  end

  defp async_opp_writer?(path) do
    source = File.read!(Path.join(@core, path))
    Regex.match?(@async, source) and Regex.match?(@opp_write, source)
  end
end
