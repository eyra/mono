defmodule Systems.Account.AuthCodeCleanupWorker do
  @moduledoc """
  Scheduled Oban worker that prunes auth_codes past their validity window,
  and the rate counters whose window has ended.

  `Account.Public.generate_otp/2` deletes prior codes for the same email when a
  new one is requested, but codes for emails that never come back accumulate.
  After the validity window they are filtered out by `active_query/1`, so this
  worker removes those rows to keep the table bounded. The sign-in code limits
  (`Account.AuthCodeLimits`) fill most rate counters, so the same run prunes
  those.
  """
  use Oban.Worker,
    priority: 3,
    max_attempts: 1

  require Logger

  alias Systems.Account
  alias Systems.Rate

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    deleted_count = Account.Public.cleanup_expired_auth_codes()

    if deleted_count > 0 do
      Logger.info("[Account.AuthCodeCleanupWorker] Deleted #{deleted_count} expired auth_codes")
    end

    deleted_counters = Rate.Public.delete_expired_counters()

    if deleted_counters > 0 do
      Logger.info(
        "[Account.AuthCodeCleanupWorker] Deleted #{deleted_counters} expired rate counters"
      )
    end

    :ok
  end
end
