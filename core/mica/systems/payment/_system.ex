defmodule Systems.Payment.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Payment.Routes
      Systems.Payment.Routes.routes()
    end
  end

  # Reconcile pay-in/payout state against the payment provider daily
  def oban_crons,
    do: [payment_reconciliation: {"0 3 * * *", Systems.Payment.ReconciliationWorker}]

  def rate_quotas,
    do: [[service: :provider_reconcile, limit: 300, unit: :call, window: :minute, scope: :global]]
end
