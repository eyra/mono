defmodule Core.Seeds.Dev do
  @moduledoc """
  Seeds for the dev server (Fly).
  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Dev] Running dev seeds")
    :ok
  end
end
