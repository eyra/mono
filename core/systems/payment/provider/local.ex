defmodule Systems.Payment.Provider.Local do
  @behaviour Systems.Payment.Provider

  require Logger

  alias Systems.Payment.Transaction

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
  def create_transaction(
        merchant_uid,
        total_amount,
        currency,
        invoice_id,
        idempotence_key,
        %Transaction.Description{} = description,
        %Transaction.Metadata{},
        opts
      )
      when is_binary(merchant_uid) and is_integer(total_amount) and total_amount > 0 and
             is_atom(currency) and is_binary(invoice_id) and is_binary(idempotence_key) do
    uid = generate_uid()

    Logger.info(
      "[Payment.Local] create_transaction uid=#{uid} invoice=#{invoice_id} currency=#{currency} merchant=#{merchant_uid} amount=#{total_amount} description=#{Transaction.Description.format(description, invoice_id)} opts=#{inspect(opts)}"
    )

    {:ok,
     %{
       uid: uid,
       status: "created",
       payment_url: "http://localhost:4000/payment/local/#{uid}",
       amount: total_amount
     }}
  end

  @impl true
  def get_transaction(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_transaction uid=#{uid}")
    {:ok, %{uid: uid, status: "created", payment_url: nil, amount: 0}}
  end

  # Withdrawals

  @impl true
  def create_withdrawal(merchant_uid, currency, attrs)
      when is_binary(merchant_uid) and is_atom(currency) and is_map(attrs) do
    uid = generate_uid()

    Logger.info(
      "[Payment.Local] create_withdrawal merchant=#{merchant_uid} currency=#{currency} uid=#{uid} attrs=#{inspect(attrs)}"
    )

    {:ok, %{uid: uid, status: "created", amount: Map.get(attrs, :amount, 0)}}
  end

  @impl true
  def get_withdrawal(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_withdrawal uid=#{uid}")
    {:ok, %{uid: uid, status: "created", amount: 0}}
  end

  defp generate_uid do
    Ecto.UUID.generate()
  end
end
