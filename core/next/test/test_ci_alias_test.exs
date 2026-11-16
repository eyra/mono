defmodule Next.TestCiAliasTest do
  # `mix test.ci` (the pre-push hook) runs each suite half in its own Mix
  # invocation. Mix's `cmd` task starts the program itself, without a shell, so
  # an environment variable must go through `env`.
  use ExUnit.Case, async: true

  defp commands,
    do: for("cmd " <> command <- Mix.Project.config()[:aliases][:"test.ci"], do: command)

  test "every command of test.ci starts a program that exists" do
    for command <- commands() do
      [program | _] = String.split(command)

      assert System.find_executable(program),
             "test.ci: #{program} (in `cmd #{command}`) is no program"
    end
  end

  test "test.ci runs the three suites: Mica's with no SaaS, Next's and Self's" do
    # Unset, so that a BUNDLE of the caller's shell doesn't run another suite twice.
    assert "env -u BUNDLE mix test.unit" in commands()
    assert "env BUNDLE=next mix test.unit" in commands()
    assert "env BUNDLE=next mix test.feature" in commands()
    assert "env BUNDLE=self mix test.unit" in commands()
    assert "env BUNDLE=self mix test.feature" in commands()
  end
end
