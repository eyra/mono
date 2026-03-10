defmodule Systems.Payment.ProviderTest do
  use Core.PaymentCase, async: true

  @moduletag :capture_log

  describe "create_merchant/1" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:create_merchant, fn %{name: "Test"} ->
        {:ok, %{uid: "m1", status: "active", kyc_level: 0}}
      end)

      assert {:ok, %{uid: "m1"}} = ProviderMock.create_merchant(%{name: "Test"})
    end
  end

  describe "get_merchant/1" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:get_merchant, fn "m1" ->
        {:ok, %{uid: "m1", status: "active", kyc_level: 100}}
      end)

      assert {:ok, %{uid: "m1", kyc_level: 100}} = ProviderMock.get_merchant("m1")
    end
  end

  describe "create_transaction/1" do
    test "returns transaction with payment url" do
      ProviderMock
      |> expect(:create_transaction, fn %{total_amount: 10_000} ->
        {:ok,
         %{
           uid: "t1",
           status: "created",
           payment_url: "https://pay.example.com/t1",
           amount: 10_000
         }}
      end)

      assert {:ok, %{uid: "t1", payment_url: url}} =
               ProviderMock.create_transaction(%{total_amount: 10_000})

      assert is_binary(url)
    end
  end

  describe "get_transaction/1" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:get_transaction, fn "t1" ->
        {:ok, %{uid: "t1", status: "completed", payment_url: nil, amount: 5000}}
      end)

      assert {:ok, %{uid: "t1", status: "completed"}} = ProviderMock.get_transaction("t1")
    end
  end

  describe "create_withdrawal/2" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:create_withdrawal, fn "m1", %{amount: 1000} ->
        {:ok, %{uid: "w1", status: "created", amount: 1000}}
      end)

      assert {:ok, %{uid: "w1", amount: 1000}} =
               ProviderMock.create_withdrawal("m1", %{amount: 1000})
    end
  end

  describe "get_withdrawal/1" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:get_withdrawal, fn "w1" ->
        {:ok, %{uid: "w1", status: "completed", amount: 500}}
      end)

      assert {:ok, %{uid: "w1", status: "completed"}} = ProviderMock.get_withdrawal("w1")
    end
  end

  describe "create_multi_transaction/1" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:create_multi_transaction, fn %{amount: 10_000} ->
        {:ok, %{uid: "mt1", status: "created"}}
      end)

      assert {:ok, %{uid: "mt1"}} =
               ProviderMock.create_multi_transaction(%{amount: 10_000})
    end
  end
end
