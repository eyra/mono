defmodule Systems.Banking.DummyTest do
  use ExUnit.Case, async: true
  alias Systems.Banking.Dummy

  setup do
    {:ok, pid: Dummy.start_link("1234")}
  end

  describe "list_payments/1" do
    test "returns the expected datastructure" do
      assert %{
               has_more?: _more,
               cursor: _cursor,
               payments: _payments
             } = Dummy.list_payments(nil)
    end

    test "since parameter only returns new payments" do
      Dummy.submit_payment(valid_payment())

      assert %{cursor: since_cursor} = Dummy.list_payments(nil)

      # There are no new payments
      assert %{payments: []} = Dummy.list_payments(since_cursor)
      # New payments are returned with an updated cursor
      Dummy.submit_payment(Map.put(valid_payment(), :idempotence_key, Faker.String.base64()))

      assert %{cursor: new_since_cursor, payments: [_payment]} = Dummy.list_payments(since_cursor)

      assert new_since_cursor != since_cursor
    end

    test "payments are batched" do
      nr_of_payments = 100

      for _ <- 0..nr_of_payments do
        :ok =
          Dummy.submit_payment(Map.put(valid_payment(), :idempotence_key, Faker.String.base64()))
      end

      assert %{cursor: since_cursor, has_more?: true, payments: payments} =
               Dummy.list_payments(nil)

      assert Enum.count(payments) < nr_of_payments
      assert %{payments: _second_payment_batch} = Dummy.list_payments(since_cursor)
    end
  end

  describe "submit_payment/1" do
    test "creates a new payment with the current date" do
      payment = valid_payment()
      assert :ok = Dummy.submit_payment(payment)

      assert %{payments: payments} = Dummy.list_payments(nil)
      assert [payment] = Enum.filter(payments, &(&1.idempotence_key == payment.idempotence_key))
      assert DateTime.diff(DateTime.utc_now(), payment.date) <= 0.1
    end

    test "submitting the same payment returns an error" do
      payment = valid_payment()
      assert :ok = Dummy.submit_payment(payment)

      assert {:error, "The payment with the given ID already exists"} =
               Dummy.submit_payment(payment)
    end
  end

  def valid_payment do
    %{
      idempotence_key: Faker.String.base64()
    }
  end
end
