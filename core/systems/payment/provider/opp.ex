defmodule Systems.Payment.Provider.OPP do
  @behaviour Systems.Payment.Provider

  alias Systems.Payment.Error
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

  # Transactions

  @impl true
  def create_transaction(attrs) when is_map(attrs) do
    case HTTP.post("/transactions", attrs) do
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
  def create_withdrawal(merchant_uid, attrs) when is_binary(merchant_uid) and is_map(attrs) do
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

  # Multi-transactions

  @impl true
  def create_multi_transaction(attrs) when is_map(attrs) do
    case HTTP.post("/multi_transactions", attrs) do
      {:ok, %{"uid" => uid} = data} ->
        {:ok, parse_multi_transaction(uid, data)}

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

  defp parse_multi_transaction(uid, data) do
    %{
      uid: uid,
      status: Map.get(data, "status", "unknown")
    }
  end
end
