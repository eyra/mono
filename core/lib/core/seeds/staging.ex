defmodule Core.Seeds.Staging do
  @moduledoc """
  Seeds for the staging server (Fly).
  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Staging] Running staging seeds")
    :ok
  end
end
