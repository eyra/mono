defmodule Mica.MixTestAliasTest do
  # `mix test` without BUNDLE runs Mica's own suite, with no SaaS, so it refuses
  # a SaaS's test file instead of running it on Mica's composition.
  use ExUnit.Case, async: true

  defp mix_test(args), do: Mix.Project.config()[:aliases][:test].(args)

  test "a test file of Next's suite needs BUNDLE=next" do
    assert_raise Mix.Error,
                 ~r"next/test/saas_test.exs is in Next's suite: run it with BUNDLE=next",
                 fn ->
                   mix_test(["next/test/saas_test.exs"])
                 end
  end

  test "a test file of Self's suite needs BUNDLE=self" do
    assert_raise Mix.Error,
                 ~r"mica_saas/test/saas_test.exs is in Self's suite: run it with BUNDLE=self",
                 fn ->
                   mix_test(["--seed", "1", "mica_saas/test/saas_test.exs"])
                 end
  end
end
