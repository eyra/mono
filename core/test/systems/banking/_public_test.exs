defmodule Systems.Banking.PublicTest do
  use Core.DataCase, async: true
  import Mox

  alias Systems.{
    Banking,
    Budget
  }

  setup :verify_on_exit!

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
        assert description =~ Budget.AccountStrategy.encode({:wallet, "euro", 888})
      end)

      Banking.Public.submit_payment(%{
        idempotence_key: idempotence_key,
        to_iban: "987",
        account: {:wallet, 888},
        amount: 5432,
        description: "A payment #{Budget.AccountStrategy.encode({:wallet, "euro", 888})}"
      })
    end
  end
end
