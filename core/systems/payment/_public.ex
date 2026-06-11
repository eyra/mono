defmodule Systems.Payment.Public do
  use Core, :public

  require Logger

  alias Core.Repo
  alias Systems.Account
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

  @spec ensure_merchant_for(Account.User.t()) ::
          {:ok, {Account.User.t(), Provider.merchant()}} | {:error, Error.t()}
  def ensure_merchant_for(%Account.User{} = user) do
    do_ensure_merchant_for(Repo.reload!(user))
  end

  defp do_ensure_merchant_for(%Account.User{merchant_uid: merchant_uid} = user)
       when is_binary(merchant_uid) do
    case get_merchant(merchant_uid) do
      {:ok, merchant} -> {:ok, {user, merchant}}
      {:error, _} = error -> error
    end
  end

  defp do_ensure_merchant_for(%Account.User{id: user_id, email: email} = user) do
    Logger.info("[Payment] Creating merchant for user ##{user_id} (#{email})")

    case create_merchant(merchant_attrs(user)) do
      {:ok, %{uid: merchant_uid} = merchant} ->
        register_merchant(user, merchant_uid, merchant)

      {:error, %{details: %{body: %{"error" => %{"parameters" => %{"emailaddress" => _}}}}}} ->
        Logger.info("[Payment] Merchant already exists for #{email}, looking up...")
        lookup_merchant_by_email(user)

      {:error, error} ->
        Logger.warning(
          "[Payment] Merchant creation failed for user ##{user_id}: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  defp register_merchant(%Account.User{id: user_id} = user, merchant_uid, merchant) do
    Logger.info("[Payment] Merchant created: #{merchant_uid} for user ##{user_id}")
    persist_merchant(user, merchant_uid, merchant)
  end

  defp persist_merchant(user, merchant_uid, merchant) do
    {:ok, user} = save_merchant_uid(user, merchant_uid)
    {:ok, {user, merchant}}
  end

  defp merchant_attrs(%Account.User{id: user_id, email: email, displayname: displayname}) do
    {first, last} = split_name(displayname)

    %{
      type: "consumer",
      emailaddress: email,
      country: "NLD",
      locale: "nl",
      name_first: first,
      name_last: last,
      notify_url: webhook_url(),
      return_url: return_url(),
      metadata: %{user_id: "#{user_id}"}
    }
  end

  defp split_name(nil), do: {"", ""}
  defp split_name(""), do: {"", ""}

  defp split_name(displayname) when is_binary(displayname) do
    case String.split(displayname, " ", parts: 2) do
      [first] -> {first, ""}
      [first, last] -> {first, last}
    end
  end

  defp return_url do
    base_url = Application.fetch_env!(:core, :base_url)
    "#{base_url}/"
  end

  defp lookup_merchant_by_email(%Account.User{email: email} = user) do
    case find_merchant_by_email(email) do
      {:ok, %{uid: merchant_uid} = merchant} ->
        Logger.info("[Payment] Found existing merchant: #{merchant_uid} for #{email}")
        persist_merchant(user, merchant_uid, merchant)

      {:error, error} ->
        Logger.warning("[Payment] Merchant lookup failed for #{email}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp save_merchant_uid(user, merchant_uid) do
    user =
      user
      |> Ecto.Changeset.change(%{merchant_uid: merchant_uid})
      |> Repo.update!()

    {:ok, user}
  end

  # Bank accounts

  @spec create_bank_account(merchant_uid :: String.t(), attrs :: map()) ::
          {:ok, Provider.bank_account()} | {:error, Error.t()}
  def create_bank_account(merchant_uid, attrs) do
    provider().create_bank_account(merchant_uid, attrs)
  end

  @spec list_bank_accounts(merchant_uid :: String.t()) ::
          {:ok, [Provider.bank_account()]} | {:error, Error.t()}
  def list_bank_accounts(merchant_uid) do
    provider().list_bank_accounts(merchant_uid)
  end

  @doc """
  Ensures the merchant has a usable bank account, creating one when it has none
  or only `disapproved` ones. Returns `{:ok, bank_account}` or `{:error, reason}`.
  """
  @spec ensure_bank_account_for(merchant_uid :: String.t()) ::
          {:ok, Provider.bank_account()} | {:error, Error.t()}
  def ensure_bank_account_for(merchant_uid) when is_binary(merchant_uid) do
    case list_bank_accounts(merchant_uid) do
      {:ok, accounts} -> usable_or_new_bank_account(merchant_uid, accounts)
      {:error, _} = error -> error
    end
  end

  defp usable_or_new_bank_account(merchant_uid, accounts) do
    case Enum.find(accounts, &(&1.status != "disapproved")) do
      nil -> create_bank_account(merchant_uid, bank_account_attrs())
      usable -> {:ok, usable}
    end
  end

  defp bank_account_attrs do
    %{
      notify_url: webhook_url(),
      return_url: return_url(),
      is_default: true
    }
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

  @spec create_withdrawal(
          merchant_uid :: String.t(),
          currency :: atom(),
          attrs :: map(),
          idempotence_key :: String.t()
        ) :: {:ok, Provider.withdrawal()} | {:error, Error.t()}
  def create_withdrawal(merchant_uid, currency, attrs, idempotence_key) do
    provider().create_withdrawal(merchant_uid, currency, attrs, idempotence_key)
  end

  @spec get_withdrawal(uid :: String.t()) :: {:ok, Provider.withdrawal()} | {:error, Error.t()}
  def get_withdrawal(uid) do
    provider().get_withdrawal(uid)
  end

  # Charges

  @spec create_charge(
          from_owner_uid :: String.t(),
          to_owner_uid :: String.t(),
          amount :: non_neg_integer(),
          idempotence_key :: String.t()
        ) :: {:ok, Provider.charge()} | {:error, Error.t()}
  def create_charge(from_owner_uid, to_owner_uid, amount, idempotence_key) do
    provider().create_charge(from_owner_uid, to_owner_uid, amount, idempotence_key)
  end

  @doc """
  The platform (eyra) merchant UID that holds the float — the `from_owner` of
  participant payout charges. Sourced from the OPP `merchant_uid` config
  (`OPP_MERCHANT_UID`).
  """
  @spec platform_merchant_uid() :: String.t() | nil
  def platform_merchant_uid do
    Application.get_env(:core, Systems.Payment.Provider.OPP, [])
    |> Keyword.get(:merchant_uid)
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
    Frameworks.Need.resolve(:payment_provider)
  end

  defp provider_name do
    provider()
    |> Module.split()
    |> List.last()
    |> String.downcase()
  end
end
