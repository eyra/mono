defmodule Core.Seeds.Prod do
  @moduledoc """
  Seeds for production (AWS).

  Intentionally empty. Production never seeds accounts: real users
  register via the normal signup flow, and admin/service accounts
  are provisioned manually via the remote console. The `:e2e`
  feature flag is off in prod, so `/api/e2e/bootstrap` is rejected
  and no test fixtures can be created.

  All operations must be idempotent.
  """

  require Logger

  def seed do
    Logger.info("[Seeds.Prod] Running prod seeds")
    :ok
  end
end
