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
    find_merchant_by_email_paged(email, 1)
  end

  defp find_merchant_by_email_paged(email, page) do
    case HTTP.get("/merchants?page=#{page}") do
      {:ok, %{"data" => merchants, "has_more" => has_more}} ->
        case Enum.find(merchants, &(Map.get(&1, "emailaddress") == email)) do
          %{"uid" => uid} = data ->
            {:ok, parse_merchant(uid, data)}

          nil when has_more ->
            find_merchant_by_email_paged(email, page + 1)

          nil ->
            {:error, %Error{code: :not_found, message: "No merchant found for #{email}"}}
        end

      {:error, %Error{}} = error ->
        error
    end
  end

  @currency_mapping %{
    EUR: "EUR",
    USD: "USD",
    GBP: "GBP"
  }

  # Transactions

  @impl true
  def create_transaction(
        merchant_uid,
        total_amount,
        currency,
        invoice_id,
        idempotence_key,
        %Transaction.Description{} = description,
        %Transaction.Metadata{} = metadata,
        opts
      )
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

  # Withdrawals

  @impl true
  def create_withdrawal(merchant_uid, currency, attrs)
      when is_binary(merchant_uid) and is_atom(currency) and is_map(attrs) do
    attrs = Map.put(attrs, :currency, Map.fetch!(@currency_mapping, currency))

    case HTTP.post("/merchants/#{merchant_uid}/withdrawals", attrs) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_withdrawal(uid, data)}

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

  defp parse_merchant(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "unknown"),
      kyc_level: Map.get(data, "compliance", %{}) |> Map.get("level", 0)
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

  defp put_opts(body, opts) do
    Enum.reduce(opts, body, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end
end
