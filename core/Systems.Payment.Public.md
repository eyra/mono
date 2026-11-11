# `Systems.Payment.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/_public.ex#L1)

# `auth_module`

# `charge_to_partner`

```elixir
@spec charge_to_partner(
  from_owner_uid :: String.t(),
  amount :: non_neg_integer(),
  idempotence_key :: String.t()
) ::
  {:ok, Systems.Payment.Provider.transfer()}
  | {:error, Systems.Payment.Error.t()}
```

# `create_bank_account`

```elixir
@spec create_bank_account(merchant_uid :: String.t(), attrs :: map()) ::
  {:ok, Systems.Payment.Provider.bank_account()}
  | {:error, Systems.Payment.Error.t()}
```

# `create_merchant`

```elixir
@spec create_merchant(attrs :: map()) ::
  {:ok, Systems.Payment.Provider.merchant()}
  | {:error, Systems.Payment.Error.t()}
```

# `create_transaction`

```elixir
@spec create_transaction(Systems.Payment.Transaction.Request.t()) ::
  {:ok, Systems.Payment.Provider.transaction()}
  | {:error, Systems.Payment.Error.t()}
```

# `create_withdrawal`

```elixir
@spec create_withdrawal(
  merchant_uid :: String.t(),
  currency :: atom(),
  attrs :: map(),
  idempotence_key :: String.t()
) ::
  {:ok, Systems.Payment.Provider.withdrawal()}
  | {:error, Systems.Payment.Error.t()}
```

# `ensure_bank_account_for`

```elixir
@spec ensure_bank_account_for(merchant_uid :: String.t()) ::
  {:ok, Systems.Payment.Provider.bank_account()}
  | {:error, Systems.Payment.Error.t()}
```

Ensures the merchant has a usable bank account, creating one when it has none
or only `disapproved` ones. Returns `{:ok, bank_account}` or `{:error, reason}`.

# `ensure_merchant_for`

```elixir
@spec ensure_merchant_for(Systems.Account.User.t(), String.t() | nil) ::
  {:ok, {Systems.Account.User.t(), Systems.Payment.Provider.merchant()}}
  | {:error, Systems.Payment.Error.t()}
```

# `find_merchant_by_email`

```elixir
@spec find_merchant_by_email(email :: String.t()) ::
  {:ok, Systems.Payment.Provider.merchant()}
  | {:error, Systems.Payment.Error.t()}
```

# `finish_reconciliation_run`

# `get_merchant`

```elixir
@spec get_merchant(uid :: String.t()) ::
  {:ok, Systems.Payment.Provider.merchant()}
  | {:error, Systems.Payment.Error.t()}
```

# `get_transaction`

```elixir
@spec get_transaction(uid :: String.t()) ::
  {:ok, Systems.Payment.Provider.transaction()}
  | {:error, Systems.Payment.Error.t()}
```

# `get_withdrawal`

```elixir
@spec get_withdrawal(uid :: String.t()) ::
  {:ok, Systems.Payment.Provider.withdrawal()}
  | {:error, Systems.Payment.Error.t()}
```

# `list_bank_accounts`

```elixir
@spec list_bank_accounts(merchant_uid :: String.t()) ::
  {:ok, [Systems.Payment.Provider.bank_account()]}
  | {:error, Systems.Payment.Error.t()}
```

# `list_charges_to_merchant`

```elixir
@spec list_charges_to_merchant(merchant_uid :: String.t()) ::
  {:ok, [Systems.Payment.Provider.transfer()]}
  | {:error, Systems.Payment.Error.t()}
```

# `list_recent_merchants`

```elixir
@spec list_recent_merchants(since :: DateTime.t()) ::
  Systems.Payment.Provider.listing(Systems.Payment.Provider.merchant())
```

Every merchant the provider created at or after `since` — the provider-side
input to the provider→local merchant scan.

# `list_recent_transactions`

```elixir
@spec list_recent_transactions(since :: DateTime.t()) ::
  Systems.Payment.Provider.listing(Systems.Payment.Provider.transaction())
```

Every transaction the provider created at or after `since`, across all
merchants — the provider-side input to the provider→local pay-in scan.

# `list_recent_transfers`

```elixir
@spec list_recent_transfers(since :: DateTime.t()) ::
  Systems.Payment.Provider.listing(Systems.Payment.Provider.transfer())
```

Every transfer the provider created at or after `since`, across all merchants.

# `list_recent_withdrawals`

```elixir
@spec list_recent_withdrawals(since :: DateTime.t()) ::
  Systems.Payment.Provider.listing(Systems.Payment.Provider.withdrawal())
```

Every withdrawal the provider created at or after `since`, across all
merchants — the provider-side input to the provider→local pass.

# `list_withdrawals`

```elixir
@spec list_withdrawals(merchant_uid :: String.t()) ::
  {:ok, [Systems.Payment.Provider.withdrawal()]}
  | {:error, Systems.Payment.Error.t()}
```

Every withdrawal the provider holds for a merchant, so one whose uid was never
recorded can still be found by its `reference`.

# `new_reconciliation_state`

# `partner_fee_amount`

```elixir
@spec partner_fee_amount(non_neg_integer()) :: non_neg_integer()
```

Partner fee in cents for the given base amount, based on `partner_fee_percentage/0`.

# `partner_fee_percentage`

```elixir
@spec partner_fee_percentage() :: non_neg_integer()
```

Percentage charged on top of the base amount as partner fee on OPP.
Returns 0 when not configured. Integer in range 0..100.

# `platform_merchant_uid`

```elixir
@spec platform_merchant_uid() :: String.t() | nil
```

The platform (eyra) merchant UID that holds the float — the `from_owner` of
participant payout transfers. Sourced from the OPP `merchant_uid` config
(`OPP_MERCHANT_UID`).

# `print_auth_roles`

# `reconcile_get_transaction`

# `reconcile_get_withdrawal`

# `reconcile_list_recent_merchants`

# `reconcile_list_recent_transactions`

# `reconcile_list_recent_transfers`

# `reconcile_list_recent_withdrawals`

# `reconciliation_scan_window`

# `set_merchant_phone`

```elixir
@spec set_merchant_phone(String.t(), String.t()) ::
  {:ok, Systems.Payment.Provider.merchant()}
  | {:error, Systems.Payment.Error.t()}
```

Sets the phone number on an existing merchant's primary contact so OPP's
`contact.phonenumber.required` requirement is satisfied via the API.

# `start_reconciliation_run`

# `transfer_to_merchant`

```elixir
@spec transfer_to_merchant(
  from_owner_uid :: String.t(),
  to_owner_uid :: String.t(),
  amount :: non_neg_integer(),
  idempotence_key :: String.t()
) ::
  {:ok, Systems.Payment.Provider.transfer()}
  | {:error, Systems.Payment.Error.t()}
```

# `webhook_url`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
