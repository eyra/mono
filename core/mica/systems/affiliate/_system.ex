defmodule Systems.Affiliate.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Affiliate.Routes
      Systems.Affiliate.Routes.routes()
    end
  end

  def rate_quotas,
    do: [[service: :recruit, limit: 5, unit: :call, window: :minute, scope: :local]]
end
