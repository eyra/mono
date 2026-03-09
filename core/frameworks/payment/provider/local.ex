defmodule Frameworks.Payment.Provider.Local do
  @behaviour Frameworks.Payment.Provider

  require Logger

  # Merchants

  @impl true
  def create_merchant(attrs) when is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_merchant uid=#{uid} attrs=#{inspect(attrs)}")
    {:ok, %{uid: uid, status: "active", kyc_level: 0}}
  end

  @impl true
  def get_merchant(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_merchant uid=#{uid}")
    {:ok, %{uid: uid, status: "active", kyc_level: 0}}
  end

  # Transactions

  @impl true
  def create_transaction(attrs) when is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_transaction uid=#{uid} attrs=#{inspect(attrs)}")
    {:ok, %{uid: uid, status: "created", payment_url: "http://localhost:4000/payment/local/#{uid}", amount: Map.get(attrs, :total_amount, 0)}}
  end

  @impl true
  def get_transaction(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_transaction uid=#{uid}")
    {:ok, %{uid: uid, status: "created", payment_url: nil, amount: 0}}
  end

  # Withdrawals

  @impl true
  def create_withdrawal(merchant_uid, attrs) when is_binary(merchant_uid) and is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_withdrawal merchant=#{merchant_uid} uid=#{uid} attrs=#{inspect(attrs)}")
    {:ok, %{uid: uid, status: "created", amount: Map.get(attrs, :amount, 0)}}
  end

  @impl true
  def get_withdrawal(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_withdrawal uid=#{uid}")
    {:ok, %{uid: uid, status: "created", amount: 0}}
  end

  # Multi-transactions

  @impl true
  def create_multi_transaction(attrs) when is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_multi_transaction uid=#{uid} attrs=#{inspect(attrs)}")
    {:ok, %{uid: uid, status: "created"}}
  end

  defp generate_uid do
    Ecto.UUID.generate()
  end
end
