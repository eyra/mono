# `Systems.Payment.Webhook`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/webhook.ex#L1)

# `category`

```elixir
@type category() :: :transaction | :withdrawal | :kyc | :ignored
```

Provider-agnostic event category. The adapter's `verify_and_parse/1` classifies
its own wire vocabulary into one of these, so `Payment.Controller` routes without
knowing any provider's event-type or object-type strings:

  * `:transaction` / `:withdrawal` — a lifecycle status change; act on `object_uid`
  * `:kyc` — a merchant/bank-account verification change; refresh `merchant_uid`
  * `:ignored` — an event the domain does not act on

# `event`

```elixir
@type event() :: %{
  category: category(),
  object_uid: String.t() | nil,
  merchant_uid: String.t() | nil,
  raw_type: String.t()
}
```

Provider-agnostic webhook event. Adapters resolve the identifiers the domain
needs (the owning `merchant_uid` for `:kyc`) so no provider wire-format detail
reaches the controller. `raw_type` is the provider's own event-type string,
retained for logging only.

# `verify_and_parse`

```elixir
@callback verify_and_parse(Plug.Conn.t()) ::
  {:ok, event()} | {:error, Systems.Payment.Error.t()}
```

# `handler`

```elixir
@spec handler(String.t()) :: {:ok, module()} | {:error, :unknown_provider}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
