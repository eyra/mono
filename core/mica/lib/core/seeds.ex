defmodule Core.Seeds do
  @moduledoc """
  Idempotent seed orchestration.

  Seeds are organized by deploy environment. `Base` runs in every environment
  and creates records that must exist everywhere (e.g. the Panl pool). Each
  environment may have its own additional seed module under `Core.Seeds.<Env>`.
  After those, each system of the SaaS seeds its own records
  (`c:Core.System.seeds/1`).

  Triggered after migrations on every deployment via `Core.Release.seed/0`.
  All seed modules must be idempotent — safe to run multiple times.
  """

  require Logger

  alias Core.Seeds

  @doc """
  Runs all seeds for the current deploy environment.

  Always runs `Base.seed/0`, then dispatches to the environment-specific
  module based on `:deploy_env` from application config, then runs the seeds
  of the SaaS's systems.
  """
  def seed do
    env = deploy_env()
    Logger.info("[Seeds] Running seeds for deploy_env=#{inspect(env)}")

    Seeds.Base.seed()
    seed_env(env)
    seed_systems(Core.SaaS.systems(), env)

    Logger.info("[Seeds] Done")
    :ok
  end

  @doc false
  def seed_systems(systems, env) do
    for system <- systems, do: :ok = system.seeds(env)
    :ok
  end

  defp seed_env(:local), do: Seeds.Local.seed()
  defp seed_env(:dev), do: Seeds.Dev.seed()
  defp seed_env(:test), do: Seeds.Test.seed()
  defp seed_env(:staging), do: Seeds.Staging.seed()
  defp seed_env(:prod), do: Seeds.Prod.seed()

  defp seed_env(other) do
    Logger.warning("[Seeds] Unknown deploy_env=#{inspect(other)}, skipping env-specific seeds")
    :ok
  end

  defp deploy_env do
    Core.Env.fetch!(:deploy_env)
  end
end
