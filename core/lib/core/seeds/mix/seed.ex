defmodule Mix.Tasks.Seed do
  @shortdoc "Runs idempotent seeds for the current deploy environment"
  @moduledoc """
  Runs `Core.Seeds.seed/0` which executes base seeds plus
  environment-specific seeds based on the `:deploy_env` config.

      $ mix seed

  All seed operations are idempotent and safe to run multiple times.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Core.Repo.start_link()

    Core.Seeds.seed()
  end
end
