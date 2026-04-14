defmodule Core.Seeds.Prod do
  @moduledoc """
  Seeds for production (AWS).
  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Prod] Running prod seeds")
    :ok
  end
end
