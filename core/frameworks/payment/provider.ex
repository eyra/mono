defmodule Frameworks.Payment.Provider do
  alias Frameworks.Payment.Error

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

  ## Attrs

    * `merchant_uid` (required) - merchant to receive the payment
    * `total_amount` (required) - amount in cents (minor units)
    * `description` - bank statement description,
      format: "<platform>, <budget>, <invoice-id>, <#participants x amount>"
    * `payment_method` - "ideal" (default, non-reversible)
    * `return_url` - redirect URL after payment completion
    * `notify_url` - webhook URL for transaction status updates
    * `metadata` - key/value pairs, used for compliance:
      * `contact_person` - researcher name
      * `study_title` - title of the study
      * `study_goal` - plain text description
      * `participant_count` - number of participants
      * `amount_per_participant` - amount per participant in cents
      * `eyra_id` - UUID linking to assignment + budget
  """
  @callback create_transaction(attrs :: map()) :: {:ok, transaction()} | {:error, Error.t()}
  @callback get_transaction(uid :: String.t()) :: {:ok, transaction()} | {:error, Error.t()}

  # Withdrawals

  @type withdrawal :: %{
          uid: String.t(),
          status: String.t(),
          amount: integer()
        }

  @doc """
  Create a payout from a merchant to a participant's bank account.

  ## Attrs

    * `amount` (required) - payout amount in cents
    * `description` - description for the bank statement
  """
  @callback create_withdrawal(merchant_uid :: String.t(), attrs :: map()) ::
              {:ok, withdrawal()} | {:error, Error.t()}
  @callback get_withdrawal(uid :: String.t()) :: {:ok, withdrawal()} | {:error, Error.t()}

  # Multi-transactions (transfers with split)

  @type multi_transaction :: %{
          uid: String.t(),
          status: String.t()
        }

  @doc """
  Transfer funds between merchants with split data for platform fees.

  ## Attrs

    * `merchant_uid` (required) - source merchant
    * `total_amount` (required) - total amount in cents
    * `splits` - list of split objects defining fee distribution
  """
  @callback create_multi_transaction(attrs :: map()) ::
              {:ok, multi_transaction()} | {:error, Error.t()}

  def provider do
    Application.fetch_env!(:core, :payment_provider)
  end
end
