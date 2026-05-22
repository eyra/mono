defmodule Core.Config do
  def payment_provider do
    name = System.get_env("PAYMENT_PROVIDER", "local")
    providers = Application.fetch_env!(:core, :payment_providers)
    Map.fetch!(providers, name)
  end
end
