defmodule Core.Seeds.Local do
  @moduledoc """
  Seeds for the local developer environment (mix dev, mix test).
  All operations must be idempotent.

  These accounts use hardcoded, well-known passwords for developer
  convenience. They are intentionally NOT seeded on dev/test/staging,
  which are publicly reachable Fly deployments where known
  credentials would be a security risk.

  The E2E service account is bootstrapped on demand via
  `/api/e2e/bootstrap` (same flow as prod) and not seeded here.
  """

  require Logger

  import Core.Seeds.Helpers

  @password "asdf;lkjASDF0987"

  def seed do
    Logger.info("[Seeds.Local] Running local seeds")

    seed_creator!("admin@panl.nl", name: "Panl Admin", password: @password)
    seed_creator!("researcher@eyra.co", name: "Researcher", password: @password)
    ensure_user!("member@eyra.co", name: "Member", password: @password)
    ensure_user!("admin@example.org", name: "Admin", password: @password)

    :ok
  end
end
