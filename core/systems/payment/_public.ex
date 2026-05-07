defmodule Systems.Payment.Public do
  use Core, :public

  alias Systems.Payment.Error
  alias Systems.Payment.Provider
  alias Systems.Payment.Transaction

  # Merchants

  @spec create_merchant(attrs :: map()) :: {:ok, Provider.merchant()} | {:error, Error.t()}
  def create_merchant(attrs) do
    provider().create_merchant(attrs)
  end

  @spec get_merchant(uid :: String.t()) :: {:ok, Provider.merchant()} | {:error, Error.t()}
  def get_merchant(uid) do
    provider().get_merchant(uid)
  end

  # Transactions

  @spec create_transaction(
          merchant_uid :: String.t(),
          total_amount :: pos_integer(),
          currency :: atom(),
          invoice_id :: String.t(),
          idempotence_key :: String.t(),
          description :: Transaction.Description.t(),
          metadata :: Transaction.Metadata.t(),
          opts :: keyword()
        ) :: {:ok, Provider.transaction()} | {:error, Error.t()}
  def create_transaction(
        merchant_uid,
        total_amount,
        currency,
        invoice_id,
        idempotence_key,
        description,
        metadata,
        opts \\ []
      ) do
    provider().create_transaction(
      merchant_uid,
      total_amount,
      currency,
      invoice_id,
      idempotence_key,
      description,
      metadata,
      opts
    )
  end

  @spec get_transaction(uid :: String.t()) :: {:ok, Provider.transaction()} | {:error, Error.t()}
  def get_transaction(uid) do
    provider().get_transaction(uid)
  end

  # Withdrawals

  @spec create_withdrawal(merchant_uid :: String.t(), currency :: atom(), attrs :: map()) ::
          {:ok, Provider.withdrawal()} | {:error, Error.t()}
  def create_withdrawal(merchant_uid, currency, attrs) do
    provider().create_withdrawal(merchant_uid, currency, attrs)
  end

  @spec get_withdrawal(uid :: String.t()) :: {:ok, Provider.withdrawal()} | {:error, Error.t()}
  def get_withdrawal(uid) do
    provider().get_withdrawal(uid)
  end

  def webhook_url do
    base_url = Application.fetch_env!(:core, :base_url)
    "#{base_url}/api/payment/webhook/#{provider_name()}"
  end

  defp provider do
    Application.fetch_env!(:core, :payment_provider)
  end

  defp provider_name do
    provider()
    |> Module.split()
    |> List.last()
    |> String.downcase()
  end
end
