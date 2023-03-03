defmodule Systems.Banking.FetcherTest do
  use Core.DataCase, async: true
  import Mox

  alias Systems.Banking.{Processor, Fetcher}

  alias Systems.{
    Bookkeeping,
    Budget
  }

  setup :verify_on_exit!

  describe "last_cursor/0" do
    test "default to nil" do
      assert Fetcher.last_cursor() == nil
    end
  end

  describe "update_marker/2" do
    test "set a new transaction marker" do
      Fetcher.update_marker("testing", 12)
      assert Fetcher.last_cursor() == "testing"
    end
  end

  describe "fetch/1" do
    setup do
      currency = Budget.Factories.create_currency("florijn", :legal, "ƒ", 2)
      bank_account = Budget.Factories.create_bank_account("test_bank", {:emoji, "🚀"}, currency)
      processor = %Processor{strategy: Systems.Budget.AccountStrategy, currency: :florijn}
      state = %{processor: processor}

      %{processor: processor, state: state, currency: currency, bank_account: bank_account}
    end

    test "don't update transaction marker without new payments", %{state: state} do
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn nil -> %{marker: "tst", transactions: []} end)
      |> expect(:list_payments, fn nil -> %{marker: "tst", transactions: []} end)

      Fetcher.fetch(state)
      Fetcher.fetch(state)
    end

    test "update transaction marker", %{state: state} do
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

      Fetcher.fetch(state)

      # The transaction marker should now have been updated
      Systems.Banking.MockBackend
      |> expect(:list_payments, fn "first" -> %{marker: "second", transactions: []} end)

      Fetcher.fetch(state)
    end

    test "process payments", %{state: state, bank_account: %{account: bank}} do
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

      Fetcher.fetch(state)
      assert Bookkeeping.Public.balance(bank) == %{credit: 1, debit: 0}
      assert Bookkeeping.Public.balance(:assorted) == %{credit: 0, debit: 1}
    end
  end
end
