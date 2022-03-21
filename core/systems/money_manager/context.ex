defmodule Systems.MoneyManager.Context do
  require Logger
  alias Systems.{Banking, Bookkeeping}
  alias Core.Repo
  alias Systems.MoneyManager.TransactionMarkerModel
  import Ecto.Query

  @accounts %{
    money_box: "MB",
    wallet: "W"
  }
  @account_map Enum.map(@accounts, fn {k, v} -> {v, k} end) |> Enum.into(%{})

  @account_patterns Map.keys(@account_map) |> Enum.join("|")
  @description_re Regex.compile!("(#{@account_patterns})\\s*(\\d+)\\s*\\/\\s*(\\w+)")

  def process_bank_transactions do
    %{marker: new_marker, transactions: transactions} =
      last_transaction_marker()
      |> Banking.Context.list_payments()

    unless Enum.empty?(transactions) do
      Enum.each(transactions, &process_bank_transaction/1)
      update_transaction_marker(new_marker, Enum.count(transactions))
    end
  end

  # amount received -> create booking & update money box
  def process_bank_transaction(
        %{id: id, amount: amount, date: date, description: description, type: type} = transaction
      ) do
    account = map_to_account(description)

    lines =
      case type do
        :received ->
          [
            %{account: :bank, debit: amount},
            %{account: account, credit: amount}
          ]

        :payed ->
          [
            %{account: account, debit: amount},
            %{account: :bank, credit: amount}
          ]
      end

    Bookkeeping.Context.enter(%{
      idempotence_key: to_string(id),
      journal_message:
        "Bank transaction: #{id} at: #{date} for: #{amount} from: #{transaction.from_iban} to: #{transaction.to_iban}",
      lines: lines
    })
  end

  def map_to_account(description) do
    case Regex.run(@description_re, String.upcase(description, :ascii)) do
      [_, type, id, checksum] -> map_to_account(type, id, checksum)
      _ -> :assorted
    end
  end

  def map_to_account(type_str, id_str, checksum) do
    type = Map.fetch!(@account_map, type_str)
    id = String.to_integer(id_str)
    account = {type, id}

    if valid_checksum?(account, checksum) do
      account
    else
      Logger.error("Checksum mismatch detected for: #{type_str}#{id_str}/#{checksum}")
      :unidentified
    end
  end

  def submit_payment(%{
        idempotence_key: idempotence_key,
        to_iban: to,
        account: account,
        amount: amount,
        description: description
      }) do
    Banking.Context.submit_payment(%{
      idempotence_key: idempotence_key,
      to: to,
      amount: amount,
      description: "#{description} #{encode_account(account)}"
    })
  end

  def encode_account({type, account_id} = account) do
    "#{map_account_type(type)}#{account_id}/#{checksum(account)}"
  end

  defp map_account_type(type) do
    Map.fetch!(@accounts, type)
  end

  def checksum({type, id}) do
    "#{type}#{id}"
    |> :erlang.crc32()
    |> Integer.to_string(32)
  end

  def valid_checksum?(account, checksum) do
    checksum(account) == checksum
  end

  def last_transaction_marker do
    from(tm in TransactionMarkerModel,
      select: tm.marker,
      order_by: [desc: tm.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def update_transaction_marker(new_marker, payment_count) do
    Repo.insert!(%TransactionMarkerModel{
      marker: new_marker,
      payment_count: payment_count
    })
  end
end
