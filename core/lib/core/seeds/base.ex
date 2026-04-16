defmodule Core.Seeds.Base do
  @moduledoc """
  Seeds that must exist in every deploy environment (local, dev, test, staging, prod).

  All operations must be idempotent.
  """

  require Logger

  alias Systems.Pool

  @doc """
  Runs all base seeds. Safe to run multiple times.
  """
  def seed do
    Logger.info("[Seeds.Base] Running base seeds")
    seed_panl_pool()
    :ok
  end

  defp seed_panl_pool do
    Logger.info("[Seeds.Base] Ensuring Panl pool exists")
    Pool.Assembly.get_or_create_panl()
  end
end
