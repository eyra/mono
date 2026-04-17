defmodule Core.Seeds.Local do
  @moduledoc """
  Seeds for the local developer environment (mix dev, mix test).
  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Local] Running local seeds")
    :ok
  end
end
