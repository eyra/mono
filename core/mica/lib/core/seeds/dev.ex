defmodule Core.Seeds.Dev do
  @moduledoc """
  Seeds for the dev server (Fly).

  Intentionally empty. The dev server is publicly reachable, so no
  accounts with known credentials are seeded here. Real users register
  via the normal signup flow; the E2E service account is bootstrapped
  on demand via `/api/e2e/bootstrap` (gated by the `:e2e` feature flag).

  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Dev] Running dev seeds")
    :ok
  end
end
