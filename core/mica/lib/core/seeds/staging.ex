defmodule Core.Seeds.Staging do
  @moduledoc """
  Seeds for the staging server (Fly).

  Intentionally empty. Staging is publicly reachable, so no accounts
  with known credentials are seeded here. The E2E service account
  is bootstrapped on demand via `/api/e2e/bootstrap` (gated by the
  `:e2e` feature flag); the load-testing service account
  (`loadtest@eyra.service`) is provisioned manually per env via
  remote console (see `core/test/load/README.md`).

  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Staging] Running staging seeds")
    :ok
  end
end
