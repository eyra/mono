defmodule Systems.Payment.Provider do
  alias Systems.Payment.Error
  alias Systems.Payment.Transaction

  # Merchants

  @type merchant :: %{
          uid: String.t(),
          status: String.t(),
          kyc_level: integer()
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
    * `locale` - language for verification screens ("nl", "en", "fr", "de")
    * `metadata` - key/value pairs for additional data
  """
  @callback create_merchant(attrs :: map()) :: {:ok, merchant()} | {:error, Error.t()}
  @callback get_merchant(uid :: String.t()) :: {:ok, merchant()} | {:error, Error.t()}

  # Transactions

  @type transaction :: %{
          uid: String.t(),
          status: String.t(),
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
  @callback create_transaction(
              merchant_uid :: String.t(),
              total_amount :: pos_integer(),
              currency :: atom(),
              invoice_id :: String.t(),
              idempotence_key :: String.t(),
              description :: Transaction.Description.t(),
              metadata :: Transaction.Metadata.t(),
              opts :: keyword()
            ) :: {:ok, transaction()} | {:error, Error.t()}
  @callback get_transaction(uid :: String.t()) :: {:ok, transaction()} | {:error, Error.t()}

  # Withdrawals

  @type withdrawal :: %{
          uid: String.t(),
          status: String.t(),
          amount: integer()
        }

  @doc """
  Create a payout from a merchant to a participant's bank account.

  The `currency` atom (e.g. `:EUR`) is mapped to the provider's native
  currency code by each implementation.

  ## Attrs

    * `amount` (required) - payout amount in cents
    * `description` - description for the bank statement
  """
  @callback create_withdrawal(merchant_uid :: String.t(), currency :: atom(), attrs :: map()) ::
              {:ok, withdrawal()} | {:error, Error.t()}
  @callback get_withdrawal(uid :: String.t()) :: {:ok, withdrawal()} | {:error, Error.t()}
end
