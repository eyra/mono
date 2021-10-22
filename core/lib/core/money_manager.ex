defmodule Core.MoneyManager do
  require Logger
  alias Core.Banking
  alias Core.Books
  alias Core.Repo
  alias Core.MoneyManager.TransactionMarker
  import Ecto.Query

  @books %{
    money_box: "MB",
    wallet: "W"
  }
  @book_map Enum.map(@books, fn {k, v} -> {v, k} end) |> Enum.into(%{})

  @book_patterns Map.keys(@book_map) |> Enum.join("|")
  @description_re Regex.compile!("(#{@book_patterns})\\s*(\\d+)\\s*\\/\\s*(\\w+)")

  def process_bank_transactions do
    %{marker: new_marker, transactions: transactions} =
      last_transaction_marker()
      |> Banking.list_payments()

    unless Enum.empty?(transactions) do
      Enum.each(transactions, &process_bank_transaction/1)
      update_transaction_marker(new_marker, Enum.count(transactions))
    end
  end

  # amount received -> create booking & update money box
  def process_bank_transaction(
        %{id: id, amount: amount, date: date, description: description, type: type} = transaction
      ) do
    book = map_to_book(description)

    lines =
      case type do
        :received ->
          [
            %{book: :bank, debit: amount},
            %{book: book, credit: amount}
          ]

        :payed ->
          [
            %{book: book, debit: amount},
            %{book: :bank, credit: amount}
          ]
      end

    Books.enter(%{
      idempotence_key: to_string(id),
      journal_message:
        "Bank transaction: #{id} at: #{date} for: #{amount} from: #{transaction.from_iban} to: #{transaction.to_iban}",
      lines: lines
    })
  end

  def map_to_book(description) do
    case Regex.run(@description_re, String.upcase(description, :ascii)) do
      [_, type, id, checksum] -> map_to_book(type, id, checksum)
      _ -> :assorted
    end
  end

  def map_to_book(type_str, id_str, checksum) do
    type = Map.fetch!(@book_map, type_str)
    id = String.to_integer(id_str)
    book = {type, id}

    if valid_checksum?(book, checksum) do
      book
    else
      Logger.error("Checksum mismatch detected for: #{type_str}#{id_str}/#{checksum}")
      :unidentified
    end
  end

  def submit_payment(%{
        idempotence_key: idempotence_key,
        to_iban: to,
        book: book,
        amount: amount,
        description: description
      }) do
    Banking.submit_payment(%{
      idempotence_key: idempotence_key,
      to: to,
      amount: amount,
      description: "#{description} #{encode_book(book)}"
    })
  end

  def encode_book({type, book_id} = book) do
    "#{map_book_type(type)}#{book_id}/#{checksum(book)}"
  end

  defp map_book_type(type) do
    Map.fetch!(@books, type)
  end

  def checksum({type, id}) do
    "#{type}#{id}"
    |> :erlang.crc32()
    |> Integer.to_string(32)
  end

  def valid_checksum?(book, checksum) do
    checksum(book) == checksum
  end

  def last_transaction_marker do
    from(tm in TransactionMarker,
      select: tm.marker,
      order_by: [desc: tm.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  def update_transaction_marker(new_marker, payment_count) do
    Repo.insert!(%TransactionMarker{
      marker: new_marker,
      payment_count: payment_count
    })
  end
end
