defmodule Systems.Payment.Provider do
  alias Systems.Payment.Error
  alias Systems.Payment.Transaction

  # Merchants

  @type merchant :: %{
          uid: String.t(),
          status: String.t(),
          kyc_level: integer(),
          compliance_status: String.t(),
          overview_url: String.t() | nil
        }

  @doc """
  Create a merchant (participant account) on the payment platform.

  ## Attrs

    * `country` (required) - ISO 3166-1 alpha-3 country code (e.g. "NLD")
    * `emailaddress` (required) - unique email for the merchant
    * `notify_url` (required) - webhook URL for status notifications
    * `type` - "consumer" (default for participants) or "business"
    * `name_first` - first name (consumer merchants)
    * `name_last` - last name (consumer merchants)
    * `phone` - phone number (satisfies the `contact.phonenumber.required`
      compliance requirement up front, so the participant is not redirected to
      OPP's hosted page to enter one)
    * `locale` - language for verification screens ("nl", "en", "fr", "de")
    * `metadata` - key/value pairs for additional data
  """
  @callback create_merchant(attrs :: map()) :: {:ok, merchant()} | {:error, Error.t()}
  @callback get_merchant(uid :: String.t()) :: {:ok, merchant()} | {:error, Error.t()}
  @callback find_merchant_by_email(email :: String.t()) :: {:ok, merchant()} | {:error, Error.t()}

  @doc """
  Set (or add) a phone number on an existing merchant's primary contact,
  satisfying OPP's `contact.phonenumber.required` compliance requirement via the
  API. Used when a merchant was created before we collected the phone, so the
  participant is not redirected to OPP's hosted merchant-overview page.
  """
  @callback add_merchant_phone(merchant_uid :: String.t(), phone :: String.t()) ::
              {:ok, merchant()} | {:error, Error.t()}

  # Bank accounts

  @typedoc """
  Provider-agnostic bank-account (KYC) verification status. Each adapter maps its
  own vocabulary onto these atoms so domain code never matches on provider status
  strings:

    * `:verified`  — approved; payouts may fire against it
    * `:rejected`  — permanently refused; never reused for a payout
    * `:new`       — created but the participant has not submitted details yet
    * `:pending`   — submitted and under review

  An unrecognised provider status maps to `:pending`: an unknown state must never
  be treated as verified (which would authorize a payout) nor as rejected. The
  provider's own word is kept alongside it as `raw_status` for the audit trail.
  """
  @type kyc_status :: :verified | :rejected | :new | :pending

  @type bank_account :: %{
          uid: String.t(),
          status: kyc_status(),
          raw_status: String.t(),
          verification_url: String.t() | nil
        }

  @doc """
  Create a bank account on the given merchant. OPP returns a
  verification_url the merchant must visit to enter their IBAN and
  complete the bank-verification step of KYC.

  ## Attrs
    * `return_url` (required) - where to send the participant after verification
    * `notify_url` (required) - webhook URL for status notifications
    * `is_default` - boolean
    * `reference` - free-form string (≤50 chars)
  """
  @callback create_bank_account(merchant_uid :: String.t(), attrs :: map()) ::
              {:ok, bank_account()} | {:error, Error.t()}

  @callback list_bank_accounts(merchant_uid :: String.t()) ::
              {:ok, [bank_account()]} | {:error, Error.t()}

  # Transactions

  @typedoc """
  Provider-agnostic lifecycle status shared by transactions, withdrawals and
  transfers. Each adapter maps its own vocabulary onto these three atoms, so
  domain code never matches on a provider's status strings. An unrecognised
  provider status maps to `:pending`: an unknown state must never finalize money
  movement.

  The provider's own word is kept alongside it as `raw_status`, so an audit trail
  can record that OPP said "disapproved" rather than the collapsed `:failed`.
  """
  @type lifecycle_status :: :pending | :completed | :failed

  @type transaction :: %{
          uid: String.t(),
          status: lifecycle_status(),
          raw_status: String.t(),
          payment_url: String.t() | nil,
          amount: integer()
        }

  @doc """
  Create a pay-in transaction (researcher topping up budget).
  Returns a payment URL for iDEAL payment.

  The `currency` atom (e.g. `:EUR`) is mapped to the provider's native
  currency code by each implementation.

  The `invoice_id` (e.g. "NEXT-NL-0128") is used in both the bank statement
  description and the metadata.

  The `idempotence_key` comes from the bookkeeping entry and prevents duplicate
  transactions on retry.

  ## Opts

    * `payment_method` - "ideal" (default, non-reversible)
    * `return_url` - redirect URL after payment completion
    * `notify_url` - webhook URL for transaction status updates
  """
  @callback create_transaction(request :: Transaction.Request.t()) ::
              {:ok, transaction()} | {:error, Error.t()}
  @callback get_transaction(uid :: String.t()) :: {:ok, transaction()} | {:error, Error.t()}

  # Withdrawals

  @type withdrawal :: %{
          uid: String.t(),
          status: lifecycle_status(),
          raw_status: String.t(),
          reference: String.t() | nil,
          amount: integer()
        }

  @doc """
  Create a payout from a merchant to a participant's bank account.

  The `currency` atom (e.g. `:EUR`) is mapped to the provider's native
  currency code by each implementation.

  The `idempotence_key` is a stable, caller-owned unique id. The provider
  passes it to the payment platform so retrying the same logical payout
  never creates a duplicate withdrawal.

  ## Attrs

    * `amount` (required) - payout amount in cents
    * `description` - description for the bank statement
  """
  @callback create_withdrawal(
              merchant_uid :: String.t(),
              currency :: atom(),
              attrs :: map(),
              idempotence_key :: String.t()
            ) ::
              {:ok, withdrawal()} | {:error, Error.t()}
  @callback get_withdrawal(uid :: String.t()) :: {:ok, withdrawal()} | {:error, Error.t()}

  @doc """
  Every withdrawal the provider holds for a merchant.

  This is how a withdrawal is found again when its uid was never recorded — the
  caller matches on `reference`, which carries the caller's own idempotence key.
  Deliberately unfiltered: these are participant merchants, which have a handful
  of withdrawals in their lifetime, so there is nothing to paginate around and no
  need to depend on a provider's filter vocabulary.
  """
  @callback list_withdrawals(merchant_uid :: String.t()) ::
              {:ok, [withdrawal()]} | {:error, Error.t()}

  # Transfers

  @type transfer :: %{
          uid: String.t(),
          status: lifecycle_status(),
          raw_status: String.t(),
          amount: integer()
        }

  @doc """
  Move funds from one merchant balance to another within the provider. Debits
  `from_owner_uid` and credits `to_owner_uid`.

  Used to fund a participant's merchant from the platform (eyra) merchant before
  the participant withdraws to their bank account. Providers name this operation
  differently (OPP: a "charge" of type `balance`; Stripe Connect: a transfer);
  that vocabulary stays inside the adapter.

  The `idempotence_key` is a stable, caller-owned unique id so retrying the same
  logical transfer never moves the money twice.
  """
  @callback transfer_to_merchant(
              from_owner_uid :: String.t(),
              to_owner_uid :: String.t(),
              amount :: non_neg_integer(),
              idempotence_key :: String.t()
            ) :: {:ok, transfer()} | {:error, Error.t()}
end
