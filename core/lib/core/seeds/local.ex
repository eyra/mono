defmodule Core.Seeds.Local do
  @moduledoc """
  Seeds for the local developer environment (mix dev, mix test).
  All operations must be idempotent.
  """

  require Logger

  import Core.Seeds.Helpers

  @password "asdf;lkjASDF0987"

  def seed do
    Logger.info("[Seeds.Local] Running local seeds")

    ensure_user!("admin@panl.nl",
      name: "Panl Admin",
      creator: true,
      password: @password
    )

    :ok
  end
end
