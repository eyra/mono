defmodule Systems.Budget.Public do
  use Core, :public

  require Logger

  import Ecto.Query

  alias Core.Repo
  alias Ecto.Multi

  alias Systems.Account
  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Payment
  alias Systems.Assignment
  alias Systems.Fund

  def list_transactions_by_fund(%Fund.Model{id: fund_id}) do
    from(t in Budget.TransactionModel,
      where: t.target_fund_id == ^fund_id,
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
  end

  def get_transaction_by_provider_uid!(provider_uid) do
    Repo.get_by!(Budget.TransactionModel, transaction_id: provider_uid)
  end

  # --- Pay-in creation ---

  @doc """
  Creates a pending transaction and initiates payment with the payment provider.
  Lazily creates an OPP merchant for the user if needed.
  Returns {:ok, %{transaction: transaction, payment_url: url}} or {:error, reason}.
  """
  def create_pay_in(
        %Assignment.Model{info: %{subject_reward: subject_reward}, fund: fund} = assignment,
        %Account.User{id: user_id} = user,
        subject_count
      )
      when is_integer(subject_count) and subject_count > 0 do
    reward_per_participant = subject_reward || 0
    base_amount = subject_count * reward_per_participant
    partner_fee = Payment.Public.partner_fee_amount(base_amount)
    total_amount = base_amount + partner_fee

    if total_amount > 0 do
      create_paid_pay_in(assignment, user, subject_count, total_amount, partner_fee)
    else
      create_free_pay_in(fund, user_id, subject_count)
    end
  end

  defp create_paid_pay_in(
         %Assignment.Model{
           info: %{
             subject_reward: subject_reward,
             title: title,
             subtitle: subtitle,
             aim_of_study: aim_of_study
           },
           fund: fund
         } = assignment,
         %Account.User{id: user_id} = user,
         subject_count,
         total_amount,
         partner_fee
       ) do
    merchant_uid = pay_in_merchant_uid(user)
    reward_per_participant = subject_reward || 0
    currency = get_currency(fund)
    idempotence_key = "pay_in:fund=#{fund.id}:#{Ecto.UUID.generate()}"
    invoice_id = generate_invoice_id()

    description = %Payment.Transaction.Description{
      platform: "Next",
      assignment: title || "Untitled",
      participant_count: subject_count,
      amount_per_participant: reward_per_participant
    }

    metadata = %Payment.Transaction.Metadata{
      contact_person: "Researcher ##{user_id}",
      study_title: title || "Untitled",
      study_goal: subtitle || "",
      aim_of_study: aim_of_study,
      participant_count: subject_count,
      amount_per_participant: reward_per_participant
    }

    return_url = return_url(assignment)

    opts = [return_url: return_url]
    opts = if partner_fee > 0, do: Keyword.put(opts, :partner_fee, partner_fee), else: opts

    request = %Payment.Transaction.Request{
      merchant_uid: merchant_uid,
      total_amount: total_amount,
      currency: currency,
      invoice_id: invoice_id,
      idempotence_key: idempotence_key,
      description: description,
      metadata: metadata,
      opts: opts
    }

    with {:ok, provider_result} <- Payment.Public.create_transaction(request),
         {:ok, transaction} <-
           %Budget.TransactionModel{}
           |> Budget.TransactionModel.changeset(%{
             transaction_id: provider_result.uid,
             status: :pending,
             idempotence_key: idempotence_key,
             invoice_id: invoice_id,
             subject_count: subject_count,
             total_amount: total_amount
           })
           |> Ecto.Changeset.put_change(:user_id, user_id)
           |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
           |> Repo.insert() do
      {:ok, %{transaction: transaction, payment_url: provider_result.payment_url}}
    end
  end

  # Pay-ins fund the platform merchant (the float for payout charges); fall back
  # to the user's own merchant only when no platform merchant is configured.
  defp pay_in_merchant_uid(user) do
    case Payment.Public.platform_merchant_uid() do
      nil ->
        {:ok, {_user, %{uid: uid}}} = Payment.Public.ensure_merchant_for(user)
        uid

      uid ->
        uid
    end
  end

  defp create_free_pay_in(%Fund.Model{id: fund_id}, user_id, subject_count) do
    idempotence_key = "pay_in:fund=#{fund_id}:#{Ecto.UUID.generate()}"
    invoice_id = generate_invoice_id()

    with {:ok, transaction} <-
           %Budget.TransactionModel{}
           |> Budget.TransactionModel.changeset(%{
             transaction_id: "free_#{Ecto.UUID.generate()}",
             status: :completed,
             idempotence_key: idempotence_key,
             invoice_id: invoice_id,
             subject_count: subject_count,
             total_amount: 0
           })
           |> Ecto.Changeset.put_change(:user_id, user_id)
           |> Ecto.Changeset.put_change(:target_fund_id, fund_id)
           |> Repo.insert() do
      increment_subject_count(fund_id, subject_count)
      {:ok, %{transaction: transaction, payment_url: nil}}
    end
  end

  # --- Transaction completion ---

  @doc """
  Completes a transaction after successful payment.
  In one atomic Multi:
  1. Update transaction status to :completed
  2. Create bookkeeping entry (debit CurrencyLedger.inbound, credit Fund.available)
  3. Increment assignment subject_count

  Money stays on the user's OPP merchant. Our bookkeeping is the source of truth
  for fund allocation. OPP withdrawals happen at payout time (UC-OPP-06).

  Status handling: `:pending` and `:failed` transactions are both completed by
  this function. The `:failed → :completed` upgrade resolves the race where the
  expiration worker marks a transaction failed before a late webhook arrives —
  the researcher's payment did succeed at OPP and we credit it. Only
  `:completed` transactions are refused (idempotency on duplicate webhooks).
  """
  def complete_transaction(provider_uid) when is_binary(provider_uid) do
    transaction =
      get_transaction_by_provider_uid!(provider_uid)
      |> Repo.preload(target_fund: [:available, :pending, currency_ledger: [:inbound, :outbound]])

    case transaction.status do
      :completed ->
        {:error, "Transaction already completed"}

      _ ->
        do_complete_transaction(transaction)
    end
  end

  defp do_complete_transaction(
         %Budget.TransactionModel{
           subject_count: subject_count,
           target_fund: %{
             available: %{identifier: fund_account_id},
             currency_ledger: %{inbound: %{identifier: inbound_account_id}}
           }
         } = transaction
       ) do
    reward_per_participant = get_reward_per_participant(transaction)
    total_amount = subject_count * reward_per_participant

    Multi.new()
    |> Multi.update(
      :transaction,
      Budget.TransactionModel.changeset(transaction, %{status: :completed})
    )
    |> Multi.run(:bookkeeping, fn _, _ ->
      Bookkeeping.Public.enter(%{
        idempotence_key: "complete:#{transaction.idempotence_key}",
        journal_message:
          "Pay-in #{total_amount} cents for #{subject_count} participants on fund ##{transaction.target_fund_id}",
        lines: [
          %{account: inbound_account_id, debit: total_amount},
          %{account: fund_account_id, credit: total_amount}
        ]
      })
    end)
    |> Multi.run(:update_subject_count, fn _, _ ->
      increment_subject_count(transaction.target_fund_id, subject_count)
    end)
    |> Repo.commit()
  end

  def fail_transaction(provider_uid) when is_binary(provider_uid) do
    transaction = get_transaction_by_provider_uid!(provider_uid)

    transaction
    |> Budget.TransactionModel.changeset(%{status: :failed})
    |> Repo.update()
  end

  @pay_in_expiration_minutes 15

  @doc """
  Marks pending pay-in transactions older than `max_age_minutes` as `:failed`.

  The OPP hosted checkout keeps the transaction open on their side, but once we've
  marked it failed locally `complete_transaction/1` refuses to complete it even if
  the webhook arrives later, so the user has to start a new pay-in.

  Returns the number of transactions that were expired.
  """
  def expire_stale_pay_ins(max_age_minutes \\ @pay_in_expiration_minutes)
      when is_integer(max_age_minutes) and max_age_minutes > 0 do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    cutoff = NaiveDateTime.add(now, -max_age_minutes * 60, :second)

    {count, _} =
      from(t in Budget.TransactionModel,
        where: t.status == :pending and t.inserted_at < ^cutoff,
        update: [set: [status: :failed, updated_at: ^now]]
      )
      |> Repo.update_all([])

    if count > 0 do
      Logger.info("[Budget] Expired #{count} stale pending pay-in(s)")
    end

    count
  end

  # --- Helpers ---

  defp get_reward_per_participant(%Budget.TransactionModel{target_fund_id: fund_id}) do
    from(a in Assignment.Model,
      join: i in assoc(a, :info),
      where: a.fund_id == ^fund_id,
      select: i.subject_reward
    )
    |> Repo.one() || 0
  end

  defp increment_subject_count(fund_id, additional_count) do
    from(i in Assignment.InfoModel,
      join: a in Assignment.Model,
      on: a.info_id == i.id,
      where: a.fund_id == ^fund_id,
      update: [inc: [subject_count: ^additional_count]]
    )
    |> Repo.update_all([])

    {:ok, :updated}
  end

  defp generate_invoice_id do
    env_id = Application.get_env(:core, :invoice_environment, "DEV")
    %{rows: [[number]]} = Repo.query!("SELECT nextval('invoice_number_seq')")
    padded = number |> Integer.to_string() |> String.pad_leading(4, "0")
    "NEXT-#{env_id}-#{padded}"
  end

  defp return_url(%Assignment.Model{id: assignment_id}) do
    base_url =
      Application.get_env(:core, :payment_webhook_base_url) ||
        Application.fetch_env!(:core, :base_url)

    "#{base_url}/assignment/#{assignment_id}/content"
  end

  defp get_currency(%{currency_ledger: %{currency: currency}}), do: currency
  defp get_currency(_), do: :EUR
end
