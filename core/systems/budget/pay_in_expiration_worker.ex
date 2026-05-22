defmodule Systems.Budget.PayInExpirationWorker do
  @moduledoc """
  Sweeper that marks pending pay-in transactions older than 15 minutes as `:failed`.

  Runs every minute via Oban cron. The window is short because a pending row
  represents an in-flight OPP hosted checkout that the researcher has abandoned
  (typically by navigating away or pressing back).

  A `:failed` transaction is still upgradable: if a late `completed` webhook
  arrives from OPP after the sweep marked it failed (the researcher really did
  pay, the webhook was just slow), `Budget.Public.complete_transaction/1` will
  promote `:failed → :completed` and book the funds. Only `:completed`
  transactions are refused (idempotency).
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
