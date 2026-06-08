defmodule Systems.Payment.Provider.Local do
  @behaviour Systems.Payment.Provider

  require Logger

  alias Systems.Payment.Transaction

  # Merchants

  # Local provider always returns a "fully verified" merchant so the pay-out
  # path works end-to-end in dev/test without hitting OPP's KYC funnel.
  defp stub_merchant(uid) do
    %{
      uid: uid,
      status: "live",
      kyc_level: 100,
      compliance_status: "verified",
      overview_url: nil
    }
  end

  @impl true
  def create_merchant(attrs) when is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_merchant uid=#{uid} attrs=#{inspect(attrs)}")
    {:ok, stub_merchant(uid)}
  end

  @impl true
  def get_merchant(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_merchant uid=#{uid}")
    {:ok, stub_merchant(uid)}
  end

  @impl true
  def find_merchant_by_email(email) when is_binary(email) do
    uid = generate_uid()
    Logger.info("[Payment.Local] find_merchant_by_email email=#{email} uid=#{uid}")
    {:ok, stub_merchant(uid)}
  end

  # Bank accounts — local stub always reports an approved one so the
  # pay-out path doesn't get stuck in KYC.

  defp stub_bank_account(uid) do
    %{uid: uid, status: "approved", verification_url: nil}
  end

  @impl true
  def create_bank_account(merchant_uid, attrs) when is_binary(merchant_uid) and is_map(attrs) do
    uid = generate_uid()
    Logger.info("[Payment.Local] create_bank_account merchant=#{merchant_uid} uid=#{uid}")
    {:ok, stub_bank_account(uid)}
  end

  @impl true
  def list_bank_accounts(merchant_uid) when is_binary(merchant_uid) do
    Logger.info("[Payment.Local] list_bank_accounts merchant=#{merchant_uid}")
    {:ok, [stub_bank_account(generate_uid())]}
  end

  # Transactions

  @impl true
  def create_transaction(%Transaction.Request{
        merchant_uid: merchant_uid,
        total_amount: total_amount,
        currency: currency,
        invoice_id: invoice_id,
        idempotence_key: idempotence_key,
        description: %Transaction.Description{} = description,
        metadata: %Transaction.Metadata{},
        opts: opts
      })
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
       payment_url: "#{CoreWeb.Endpoint.url()}/payment/local/#{uid}",
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
  def create_withdrawal(merchant_uid, currency, attrs, idempotence_key)
      when is_binary(merchant_uid) and is_atom(currency) and is_map(attrs) and
             is_binary(idempotence_key) do
    uid = generate_uid()

    Logger.info(
      "[Payment.Local] create_withdrawal merchant=#{merchant_uid} currency=#{currency} uid=#{uid} idempotence_key=#{idempotence_key} attrs=#{inspect(attrs)}"
    )

    {:ok, %{uid: uid, status: "created", amount: Map.get(attrs, :amount, 0)}}
  end

  @impl true
  def get_withdrawal(uid) when is_binary(uid) do
    Logger.info("[Payment.Local] get_withdrawal uid=#{uid}")
    {:ok, %{uid: uid, status: "created", amount: 0}}
  end

  @impl true
  def create_charge(from_owner_uid, to_owner_uid, amount, idempotence_key)
      when is_binary(from_owner_uid) and is_binary(to_owner_uid) and
             is_integer(amount) and amount > 0 and is_binary(idempotence_key) do
    uid = generate_uid()

    Logger.info(
      "[Payment.Local] create_charge from=#{from_owner_uid} to=#{to_owner_uid} amount=#{amount} uid=#{uid} idempotence_key=#{idempotence_key}"
    )

    {:ok, %{uid: uid, status: "created", amount: amount}}
  end

  defp generate_uid do
    Ecto.UUID.generate()
  end
end
