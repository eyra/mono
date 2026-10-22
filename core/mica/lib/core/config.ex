defmodule Core.Config do
  def payment_provider do
    name =
      case System.get_env("PAYMENT_PROVIDER") do
        value when is_binary(value) and value != "" ->
          value

        _ ->
          raise """
          PAYMENT_PROVIDER is not set.

          Set it to one of the configured payment providers (see :payment_providers,
          e.g. "opp" or "local"). Refusing to boot rather than silently falling back
          to a default, which would route real payments through the wrong adapter and
          exclude them from reconciliation.
          """
      end

    providers = Application.fetch_env!(:core, :payment_providers)
    Map.fetch!(providers, name)
  end
end
