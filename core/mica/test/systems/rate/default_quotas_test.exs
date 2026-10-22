defmodule Systems.Rate.DefaultQuotasTest do
  use ExUnit.Case, async: true

  alias Systems.Rate.Quota

  @limited_services ~w(otp_request signup recruit storage_export feldspar_data_donation feldspar_log provider_reconcile)

  # RATE_QUOTAS as the production inventory sets it: some services, not all.
  @rate_quotas """
  [{"service": "storage_export", "limit": 6, "unit": "call", "window": "minute", "scope": "local"},
   {"service": "signup", "limit": 5, "unit": "call", "window": "minute", "scope": "local"},
   {"service": "recruit", "limit": 5, "unit": "call", "window": "minute", "scope": "local"}]
  """

  setup_all do
    rate = Config.Reader.read!("config/config.exs", env: :prod, target: :host)[:core][:rate]
    %{defaults: Enum.map(Keyword.fetch!(rate, :quotas), &Quota.init/1)}
  end

  for service <- @limited_services do
    @service service
    test "a release has a #{service} quota by default", %{defaults: defaults} do
      assert Enum.any?(defaults, &(&1.service == @service))
    end

    test "a release keeps a #{service} quota when RATE_QUOTAS lists other services",
         %{defaults: defaults} do
      overrides = @rate_quotas |> Jason.decode!() |> Enum.map(&Quota.init/1)

      assert Enum.any?(Quota.merge(defaults, overrides), &(&1.service == @service))
    end
  end
end
