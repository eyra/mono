defmodule Mix.Tasks.E2e do
  @shortdoc "Run Playwright E2E tests against an environment"

  @moduledoc """
  Run Playwright E2E tests in `core/test/e2e/` against any environment.

      mix e2e                     # local (http://localhost:4000)
      mix e2e --env=local         # local
      mix e2e --env=dev           # https://eyra-next-dev.fly.dev
      mix e2e --env=test1         # https://eyra-next-test1.fly.dev
      mix e2e --env=test2         # https://eyra-next-test2.fly.dev
      mix e2e --env=staging       # https://eyra-next-staging.fly.dev
      mix e2e --headed            # show browser window
      mix e2e --browser=chromium  # chromium | webkit | firefox (default chromium)
      mix e2e --env=test1 panl_onboarding   # filter to one test file

  Non-local environments use Infisical for secrets — run
  `infisical login` from `core/test/e2e` first if you haven't yet.
  """

  use Mix.Task

  @envs ~w(local dev test1 test2 staging)
  @e2e_dir "test/e2e"

  @impl true
  def run(args) do
    {opts, args, _invalid} =
      OptionParser.parse(args,
        switches: [env: :string, headed: :boolean, browser: :string],
        aliases: [e: :env]
      )

    env = Keyword.get(opts, :env, "local")
    validate_env!(env)

    flags = playwright_flags(opts, args)
    {cmd, env_vars} = build(env, flags)

    Mix.shell().info("[e2e] env=#{env}")
    Mix.shell().info("[e2e] #{cmd}")

    {_output, exit_code} =
      System.cmd("sh", ["-c", cmd],
        cd: @e2e_dir,
        env: env_vars,
        into: IO.stream()
      )

    if exit_code != 0, do: exit({:shutdown, exit_code})
  end

  defp validate_env!(env) when env in @envs, do: :ok

  defp validate_env!(env) do
    Mix.raise("Unknown env #{inspect(env)}. Valid: #{Enum.join(@envs, ", ")}")
  end

  defp build("local", flags) do
    {"npx playwright test #{flags}", [{"E2E_BASE_URL", "http://localhost:4000"}]}
  end

  defp build(env, flags) do
    {"infisical run --env=#{env} -- npx playwright test #{flags}", []}
  end

  defp playwright_flags(opts, args) do
    browser = Keyword.get(opts, :browser, "chromium")
    parts = ["--project=#{browser}"]
    parts = if Keyword.get(opts, :headed, false), do: parts ++ ["--headed"], else: parts
    Enum.join(parts ++ args, " ")
  end
end
