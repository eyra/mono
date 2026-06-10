defmodule Systems.Payment.Provider.OPP do
  @behaviour Systems.Payment.Provider

  alias Systems.Payment.Error
  alias Systems.Payment.Transaction
  alias Systems.Payment.Provider.OPP.HTTP

  # Merchants

  @impl true
  def create_merchant(attrs) when is_map(attrs) do
    case HTTP.post("/merchants", attrs) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_merchant(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  @impl true
  def get_merchant(uid) when is_binary(uid) do
    case HTTP.get("/merchants/#{uid}") do
      {:ok, data} ->
        {:ok, parse_merchant(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  @impl true
  def find_merchant_by_email(email) when is_binary(email) do
    # Trust OPP's `filter[emailaddress]` (rows don't echo the email): take the
    # first match — the recovery path only needs a working uid.
    query =
      URI.encode_query(%{
        "filter[emailaddress]" => email,
        "perpage" => "100"
      })

    case HTTP.get("/merchants?#{query}") do
      {:ok, %{"data" => [%{"uid" => uid} = data | _]}} ->
        {:ok, parse_merchant(uid, data)}

      {:ok, %{"data" => []}} ->
        {:error, %Error{code: :not_found, message: "No merchant found for #{email}"}}

      {:error, %Error{}} = error ->
        error
    end
  end

  @currency_mapping %{
    EUR: "EUR",
    USD: "USD",
    GBP: "GBP"
  }

  @default_withdrawal_description "Payout"

  # Transactions

  @impl true
  def create_transaction(%Transaction.Request{
        merchant_uid: merchant_uid,
        total_amount: total_amount,
        currency: currency,
        invoice_id: invoice_id,
        idempotence_key: idempotence_key,
        description: %Transaction.Description{} = description,
        metadata: %Transaction.Metadata{} = metadata,
        opts: opts
      })
      when is_binary(merchant_uid) and is_integer(total_amount) and total_amount > 0 and
             is_atom(currency) and is_binary(invoice_id) and is_binary(idempotence_key) do
    notify_url = Systems.Payment.Public.webhook_url()

    body =
      %{
        merchant_uid: merchant_uid,
        total_amount: total_amount,
        currency: Map.fetch!(@currency_mapping, currency),
        description: Transaction.Description.format(description, invoice_id),
        metadata: Transaction.Metadata.to_map(metadata, invoice_id),
        notify_url: notify_url,
        products: [
          %{
            name: "Participant slots",
            quantity: description.participant_count,
            price: description.amount_per_participant
          }
        ],
        total_price: total_amount
      }
      |> put_opts(opts)

    case HTTP.post("/transactions", body, [{"Idempotency-Key", idempotence_key}]) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_transaction(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  @impl true
  def get_transaction(uid) when is_binary(uid) do
    case HTTP.get("/transactions/#{uid}") do
      {:ok, data} ->
        {:ok, parse_transaction(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  # Bank accounts

  @impl true
  def create_bank_account(merchant_uid, attrs) when is_binary(merchant_uid) and is_map(attrs) do
    case HTTP.post("/merchants/#{merchant_uid}/bank_accounts", attrs) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_bank_account(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  @impl true
  def list_bank_accounts(merchant_uid) when is_binary(merchant_uid) do
    case HTTP.get("/merchants/#{merchant_uid}/bank_accounts?perpage=100") do
      {:ok, %{"data" => entries}} ->
        {:ok, Enum.map(entries, fn %{"uid" => uid} = data -> parse_bank_account(uid, data) end)}

      {:error, %Error{}} = error ->
        error
    end
  end

  # Withdrawals

  @impl true
  def create_withdrawal(merchant_uid, currency, attrs, idempotence_key)
      when is_binary(merchant_uid) and is_atom(currency) and is_map(attrs) and
             is_binary(idempotence_key) do
    # Unknown currency must return an error (not raise) so the caller can revert.
    case Map.fetch(@currency_mapping, currency) do
      {:ok, code} ->
        # OPP 400s without description + notify_url; notify_url drives our webhook.
        body =
          attrs
          |> Map.put(:currency, code)
          |> Map.put(:reference, idempotence_key)
          |> Map.put_new(:description, @default_withdrawal_description)
          |> Map.put(:notify_url, Systems.Payment.Public.webhook_url())

        post_withdrawal(merchant_uid, body, idempotence_key)

      :error ->
        {:error,
         %Error{
           code: :unsupported_currency,
           message: "Unsupported currency: #{inspect(currency)}"
         }}
    end
  end

  defp post_withdrawal(merchant_uid, body, idempotence_key) do
    case HTTP.post("/merchants/#{merchant_uid}/withdrawals", body, [
           {"Idempotency-Key", idempotence_key}
         ]) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_withdrawal(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  # Charges

  @impl true
  def create_charge(from_owner_uid, to_owner_uid, amount, idempotence_key)
      when is_binary(from_owner_uid) and is_binary(to_owner_uid) and
             is_integer(amount) and amount > 0 and is_binary(idempotence_key) do
    body = %{
      type: "balance",
      amount: Integer.to_string(amount),
      from_owner_uid: from_owner_uid,
      to_owner_uid: to_owner_uid
    }

    case HTTP.post("/charges", body, [{"Idempotency-Key", idempotence_key}]) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_charge(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  @impl true
  def get_withdrawal(uid) when is_binary(uid) do
    case HTTP.get("/withdrawals/#{uid}") do
      {:ok, data} ->
        {:ok, parse_withdrawal(uid, data)}

      {:error, %Error{}} = error ->
        error
    end
  end

  # Parsers

  defp parse_bank_account(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "new"),
      verification_url: Map.get(data, "verification_url")
    }
  end

  defp parse_merchant(uid, data) do
    compliance = Map.get(data, "compliance", %{})

    %{
      uid: uid,
      status: Map.get(data, "status", "unknown"),
      kyc_level: Map.get(compliance, "level", 0),
      compliance_status: Map.get(compliance, "status", "unverified"),
      overview_url: Map.get(compliance, "overview_url")
    }
  end

  defp parse_transaction(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "unknown"),
      payment_url: Map.get(data, "redirect_url"),
      amount: Map.get(data, "total_amount", 0)
    }
  end

  defp parse_withdrawal(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "unknown"),
      amount: Map.get(data, "amount", 0)
    }
  end

  defp parse_charge(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "unknown"),
      amount: Map.get(data, "amount", 0)
    }
  end

  defp put_opts(body, opts) do
    Enum.reduce(opts, body, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end
end
