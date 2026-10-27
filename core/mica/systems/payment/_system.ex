defmodule Systems.Payment.System do
  use Core.System

  def routes do
    quote do
      require Systems.Payment.Routes
      Systems.Payment.Routes.routes()
    end
  end

  def rate_quotas,
    do: [[service: :provider_reconcile, limit: 300, unit: :call, window: :minute, scope: :global]]
end
