defmodule BankingClientTest do
  use ExUnit.Case, async: true
  import Mox
  alias BankingClient

  describe "list_payments/1" do
    test "can call list payments" do
      BankingClient.MockClient
      |> expect(:send_message, fn %{call: :list_payments} ->
        %{}
      end)

      %{payments: payments} = BankingClient.list_payments(nil)
      assert payments == []
    end

    test "can list payments" do
      BankingClient.MockClient
      |> expect(:send_message, fn %{call: :list_payments} ->
        %{
          "cursor" => "some-cursor",
          "has_more?" => false,
          "payments" => [
            %{
              "amount_in_cents" => -1079,
              "date" => "2021-12-19 08:35:52.779444",
              "description" => "some invoice",
              "id" => 123_456_789,
              "payment_alias" => %{"iban" => "NL10BUNQ1234567890", "name" => "My Corp"},
              "payment_counterparty_alias" => %{
                "iban" => "NL89BUNQ0987654321",
                "name" => "Mega Corp"
              }
            }
          ]
        }
      end)

      %{payments: [payment]} = BankingClient.list_payments(nil)

      assert %{
               amount_in_cents: -1079,
               date: ~N[2021-12-19 08:35:52],
               description: "some invoice",
               id: 123_456_789,
               payment_alias: %BankingClient.PaymentAlias{
                 iban: "NL10BUNQ1234567890",
                 name: "My Corp"
               },
               payment_counterparty_alias: %BankingClient.PaymentAlias{
                 iban: "NL89BUNQ0987654321",
                 name: "Mega Corp"
               }
             } = payment
    end

    test "can list payments from cursor" do
      BankingClient.MockClient
      |> expect(:send_message, fn %{call: :list_payments, cursor: "some-cursor"} ->
        %{
          "cursor" => "some-cursor",
          "has_more?" => false,
          "payments" => [
            %{
              "amount_in_cents" => -1079,
              "date" => "2021-12-19 08:35:52.779444",
              "description" => "some invoice",
              "id" => 123_456_789,
              "payment_alias" => %{"iban" => "NL10BUNQ1234567890", "name" => "My Corp"},
              "payment_counterparty_alias" => %{
                "iban" => "NL89BUNQ0987654321",
                "name" => "Mega Corp"
              }
            }
          ]
        }
      end)

      # Assume a previously defined cursor
      assert %{payments: [payment]} = BankingClient.list_payments("some-cursor")

      assert %{id: 123_456_789} = payment
    end
  end
end
