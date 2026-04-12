defmodule Core.Seeds.Test do
  @moduledoc """
  Seeds for the test servers (Fly, multiple testN environments).
  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Test] Running test seeds")
    :ok
  end
end
