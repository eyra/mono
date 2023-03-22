defmodule Systems.Banking.ProcessorTest do
  use Core.DataCase, async: true
  import ExUnit.CaptureLog
  import Mox
  alias Systems.{Banking, Bookkeeping, Budget}

  setup :verify_on_exit!

  describe "next/2" do
    setup do
      currency = Budget.Factories.create_currency("florijn", :legal, "ƒ", 2)
      bank_account = Budget.Factories.create_bank_account("test_bank", {:emoji, "🚀"}, currency)
      processor = %Banking.Processor{strategy: Systems.Budget.AccountStrategy, currency: :florijn}
      wallet = Budget.Factories.create_wallet(1, currency)

      %{processor: processor, bank_account: bank_account, currency: currency, wallet: wallet}
    end

    test "create booking when money box receives budget", %{
      processor: processor,
      bank_account: %{account: bank},
      wallet: wallet
    } do
      {:ok, _} =
        Banking.Processor.next(processor, %{
          id: 1,
          date: DateTime.utc_now(),
          description: "A transaction with #{Budget.AccountStrategy.encode(wallet)}",
          amount: 89,
          type: :received,
          from_iban: "2342",
          to_iban: "2143"
        })

      assert Bookkeeping.Public.balance(bank) == %{credit: 0, debit: 89}
      assert Bookkeeping.Public.balance(wallet) == %{credit: 89, debit: 0}
    end

    test "book non-system related transactions to 'assorted'", %{
      processor: processor,
      bank_account: %{account: bank}
    } do
      {:ok, _} =
        Banking.Processor.next(processor, %{
          id: 1,
          date: DateTime.utc_now(),
          description: "Something which can not be mapped",
          amount: 543,
          type: :received,
          from_iban: "2342",
          to_iban: "2143"
        })

      assert Bookkeeping.Public.balance(bank) == %{credit: 0, debit: 543}
      assert Bookkeeping.Public.balance(:assorted) == %{credit: 543, debit: 0}
    end

    test "unrelated payment booking", %{processor: processor} do
      {:ok, _} =
        Banking.Processor.next(processor, %{
          id: 1,
          date: DateTime.utc_now(),
          description: "A description",
          amount: 6789,
          type: :payed,
          from_iban: "1",
          to_iban: "2"
        })

      assert Bookkeeping.Public.balance(:assorted) == %{credit: 0, debit: 6789}
    end

    test "wallet payment booking", %{processor: processor, wallet: wallet} do
      {:ok, _} =
        Banking.Processor.next(processor, %{
          id: 1,
          date: DateTime.utc_now(),
          description: "A description #{Budget.AccountStrategy.encode(wallet)}",
          amount: 789,
          type: :payed,
          from_iban: "1",
          to_iban: "2"
        })

      assert Bookkeeping.Public.balance(wallet) == %{credit: 0, debit: 789}
    end

    # received is a problem, outgoing can be booked on assorted
    test "account non-matching checksum into unidentified", %{
      processor: processor,
      wallet: wallet
    } do
      account_id =
        wallet
        |> Budget.AccountStrategy.encode()
        |> String.replace("KOE", "AAP")

      assert capture_log(fn ->
               {:ok, _} =
                 Banking.Processor.next(processor, %{
                   id: 1,
                   date: DateTime.utc_now(),
                   description: "A description #{account_id}",
                   amount: 789,
                   type: :payed,
                   from_iban: "1",
                   to_iban: "2"
                 })
             end) =~ "Checksum mismatch"

      # The wallet should not have been altered
      assert Bookkeeping.Public.balance(wallet) == %{credit: 0, debit: 0}
      assert Bookkeeping.Public.balance(wallet) == %{credit: 0, debit: 0}
      # A booking should have been made on the unidentified account
      assert Bookkeeping.Public.balance(:unidentified) == %{credit: 0, debit: 789}
    end
  end
end
