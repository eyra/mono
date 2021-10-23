defmodule Systems.MoneyManager.ContextTest do
  use Core.DataCase, async: true
  import ExUnit.CaptureLog
  import Mox
  alias Systems.{MoneyManager, Bookkeeping}

  setup :verify_on_exit!

  describe "checksum/1" do
    for {type, id, expected} <- [{:money_box, 123, "R80LM4"}, {:wallet, 1122, "1LQEFB1"}] do
      test "makes a string from #{type}, #{id}" do
        assert MoneyManager.Context.checksum({unquote(type), unquote(id)}) == unquote(expected)
      end
    end
  end

  describe "valid_checksum?/2" do
    test "returns true for correct checksum" do
      checksum = MoneyManager.Context.checksum({:wallet, 987})
      assert MoneyManager.Context.valid_checksum?({:wallet, 987}, checksum)
    end

    test "returns false for invalid checksum" do
      checksum = MoneyManager.Context.checksum({:wallet, 987})
      refute MoneyManager.Context.valid_checksum?({:wallet, 887}, checksum)
    end
  end

  describe "process_bank_transaction/1" do
    test "create booking when money box receives budget" do
      :ok =
        MoneyManager.Context.process_bank_transaction(%{
          id: 1,
          date: DateTime.utc_now(),
          description:
            "A transaction with #{MoneyManager.Context.encode_book({:money_box, 123})}",
          amount: 89,
          type: :received,
          from_iban: "2342",
          to_iban: "2143"
        })

      assert Bookkeeping.Context.balance(:bank) == %{credit: 0, debit: 89}
      assert Bookkeeping.Context.balance({:money_box, 123}) == %{credit: 89, debit: 0}
    end

    test "book non-system related transactions to 'assorted'" do
      :ok =
        MoneyManager.Context.process_bank_transaction(%{
          id: 1,
          date: DateTime.utc_now(),
          description: "Something which can not be mapped",
          amount: 543,
          type: :received,
          from_iban: "2342",
          to_iban: "2143"
        })

      assert Bookkeeping.Context.balance(:bank) == %{credit: 0, debit: 543}
      assert Bookkeeping.Context.balance(:assorted) == %{credit: 543, debit: 0}
    end

    test "unrelated payment booking" do
      :ok =
        MoneyManager.Context.process_bank_transaction(%{
          id: 1,
          date: DateTime.utc_now(),
          description: "A description",
          amount: 6789,
          type: :payed,
          from_iban: "1",
          to_iban: "2"
        })

      assert Bookkeeping.Context.balance(:assorted) == %{credit: 0, debit: 6789}
    end

    test "wallet payment booking" do
      :ok =
        MoneyManager.Context.process_bank_transaction(%{
          id: 1,
          date: DateTime.utc_now(),
          description: "A description #{MoneyManager.Context.encode_book({:wallet, 123})}",
          amount: 789,
          type: :payed,
          from_iban: "1",
          to_iban: "2"
        })

      assert Bookkeeping.Context.balance({:wallet, 123}) == %{credit: 0, debit: 789}
    end

    # received is a problem, outgoing can be booked on assorted
    test "book non-matching checksum into unidentified" do
      book_id =
        {:wallet, 123}
        |> MoneyManager.Context.encode_book()
        |> String.replace("123", "223")

      assert capture_log(fn ->
               :ok =
                 MoneyManager.Context.process_bank_transaction(%{
                   id: 1,
                   date: DateTime.utc_now(),
                   description: "A description #{book_id}",
                   amount: 789,
                   type: :payed,
                   from_iban: "1",
                   to_iban: "2"
                 })
             end) =~ "Checksum mismatch"

      # The wallet should not have been altered
      assert Bookkeeping.Context.balance({:wallet, 123}) == %{credit: 0, debit: 0}
      assert Bookkeeping.Context.balance({:wallet, 223}) == %{credit: 0, debit: 0}
      # A booking should have been made on the unidentified book
      assert Bookkeeping.Context.balance(:unidentified) == %{credit: 0, debit: 789}
    end
  end

  describe "submit_payment/1" do
    test "create banking transaction with book info in description" do
      idempotence_key = Faker.String.base64()

      Systems.Banking.MockBackend
      |> expect(:submit_payment, fn %{
                                      idempotence_key: ^idempotence_key,
                                      to: "987",
                                      amount: 5432,
                                      description: description
                                    } ->
        assert description =~ MoneyManager.Context.encode_book({:wallet, 888})
      end)

      MoneyManager.Context.submit_payment(%{
        idempotence_key: idempotence_key,
        to_iban: "987",
        book: {:wallet, 888},
        amount: 5432,
        description: "A payment"
      })
    end
  end

  describe "encode_book/1" do
    for {{type, id} = book, expected} <- [
          {{:wallet, 2345}, "W2345/2PAGT64"},
          {{:money_box, 3456}, "MB3456/1SLJRQK"}
        ] do
      test "encode book: #{type}, #{id}" do
        assert MoneyManager.Context.encode_book(unquote(book)) == unquote(expected)
      end
    end
  end

  describe "last_transaction_marker/0" do
    test "default to nil" do
      assert MoneyManager.Context.last_transaction_marker() == nil
    end
  end

  describe "update_transaction_marker/2" do
    test "set a new transaction marker" do
      MoneyManager.Context.update_transaction_marker("testing", 12)
      assert MoneyManager.Context.last_transaction_marker() == "testing"
    end
  end

  describe "process_bank_transaction/0" do
    test "don't update transaction marker without new payments" do
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn nil -> %{marker: "tst", transactions: []} end)
      |> expect(:list_payments, fn nil -> %{marker: "tst", transactions: []} end)

      MoneyManager.Context.process_bank_transactions()
      MoneyManager.Context.process_bank_transactions()
    end

    test "update transaction marker" do
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn nil ->
        %{
          marker: "first",
          transactions: [
            %{
              id: "",
              amount: 1,
              date: DateTime.utc_now(),
              description: "",
              type: :payed,
              from_iban: "123",
              to_iban: "456"
            }
          ]
        }
      end)

      MoneyManager.Context.process_bank_transactions()

      # The transaction marker should now have been updated
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn "first" -> %{marker: "second", transactions: []} end)

      MoneyManager.Context.process_bank_transactions()
    end

    test "process payments" do
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn nil ->
        %{
          marker: "marker",
          transactions: [
            %{
              id: 123,
              amount: 1,
              date: DateTime.utc_now(),
              description: "Some payment",
              type: :payed,
              from_iban: "123",
              to_iban: "456"
            }
          ]
        }
      end)

      MoneyManager.Context.process_bank_transactions()
      assert Bookkeeping.Context.balance(:bank) == %{credit: 1, debit: 0}
      assert Bookkeeping.Context.balance(:assorted) == %{credit: 0, debit: 1}
    end
  end
end
