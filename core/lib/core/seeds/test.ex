defmodule Core.Seeds.Test do
  @moduledoc """
  Seeds for the test servers (Fly, multiple testN environments).

  Intentionally empty. Test servers are publicly reachable, so no
  accounts with known credentials are seeded here. The E2E service
  account (`e2e@eyra.service`) is created on demand by the Playwright
  global-setup via `/api/e2e/bootstrap` (gated by the `:e2e` feature
  flag), and the subsequent `/api/e2e/setup` call provisions the
  researcher, participant, assignment, and PaNL fixtures.

  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Test] Running test seeds")
    :ok
  end
end
