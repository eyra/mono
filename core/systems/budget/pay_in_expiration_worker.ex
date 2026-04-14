defmodule Systems.Budget.PayInExpirationWorker do
  @moduledoc """
  Sweeper that marks pending pay-in transactions older than 15 minutes as `:failed`.

  Runs every minute via Oban cron. The window is short because a pending row
  represents an in-flight OPP hosted checkout that the researcher has abandoned
  (typically by navigating away or pressing back). Once marked failed, any
  late-arriving `completed` webhook from OPP is refused by
  `Budget.Public.complete_transaction/1`, so the researcher must start a new
  pay-in.
  """
  use Oban.Worker, max_attempts: 1

  alias Systems.Budget

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    max_age_minutes = Map.get(args, "max_age_minutes", 15)
    _ = Budget.Public.expire_stale_pay_ins(max_age_minutes)
    :ok
  end
end
