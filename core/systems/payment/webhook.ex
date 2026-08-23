defmodule Systems.Payment.Webhook do
  alias Systems.Payment.Error

  @typedoc """
  Provider-agnostic event category. The adapter's `verify_and_parse/1` classifies
  its own wire vocabulary into one of these, so `Payment.Controller` routes without
  knowing any provider's event-type or object-type strings:

    * `:transaction` / `:withdrawal` — a lifecycle status change; act on `object_uid`
    * `:kyc` — a merchant/bank-account verification change; refresh `merchant_uid`
    * `:ignored` — an event the domain does not act on
  """
  @type category :: :transaction | :withdrawal | :kyc | :ignored

  @typedoc """
  Provider-agnostic webhook event. Adapters resolve the identifiers the domain
  needs (the owning `merchant_uid` for `:kyc`) so no provider wire-format detail
  reaches the controller. `raw_type` is the provider's own event-type string,
  retained for logging only.
  """
  @type event :: %{
          category: category(),
          object_uid: String.t() | nil,
          merchant_uid: String.t() | nil,
          raw_type: String.t()
        }

  @callback verify_and_parse(Plug.Conn.t()) :: {:ok, event()} | {:error, Error.t()}

  @spec handler(String.t()) :: {:ok, module()} | {:error, :unknown_provider}
  def handler(provider_name) do
    providers = Application.fetch_env!(:core, :payment_providers)

    case Map.fetch(providers, provider_name) do
      {:ok, base_module} -> {:ok, Module.concat(base_module, Webhook)}
      :error -> {:error, :unknown_provider}
    end
  end
end
