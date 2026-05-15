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

  @spec find_merchant_by_email(email :: String.t()) ::
          {:ok, Provider.merchant()} | {:error, Error.t()}
  def find_merchant_by_email(email) do
    provider().find_merchant_by_email(email)
  end

  # Transactions

  @spec create_transaction(Transaction.Request.t()) ::
          {:ok, Provider.transaction()} | {:error, Error.t()}
  def create_transaction(%Transaction.Request{} = request) do
    provider().create_transaction(request)
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
    base_url =
      Application.get_env(:core, :payment_webhook_base_url) ||
        Application.fetch_env!(:core, :base_url)

    "#{base_url}/api/payment/webhook/#{provider_name()}"
  end

  @doc """
  Percentage charged on top of the base amount as partner fee on OPP.
  Returns 0 when not configured. Integer in range 0..100.
  """
  @spec partner_fee_percentage() :: non_neg_integer()
  def partner_fee_percentage do
    Application.get_env(:core, Systems.Payment.Provider.OPP, [])
    |> Keyword.get(:partner_fee_percentage, 0)
  end

  @doc """
  Partner fee in cents for the given base amount, based on `partner_fee_percentage/0`.
  """
  @spec partner_fee_amount(non_neg_integer()) :: non_neg_integer()
  def partner_fee_amount(base_amount) when is_integer(base_amount) and base_amount >= 0 do
    div(base_amount * partner_fee_percentage(), 100)
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
