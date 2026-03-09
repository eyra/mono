defmodule Frameworks.Payment.ProviderTest do
  use ExUnit.Case, async: true

  alias Frameworks.Payment.Provider

  import Mox

  Mox.defmock(Frameworks.Payment.ProviderMock, for: Provider)

  setup :verify_on_exit!

  describe "create_merchant/1" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:create_merchant, fn %{name: "Test"} ->
        {:ok, %{uid: "m1", status: "active", kyc_level: 0}}
      end)

      assert {:ok, %{uid: "m1"}} = Provider.provider().create_merchant(%{name: "Test"})
    end
  end

  describe "get_merchant/1" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:get_merchant, fn "m1" ->
        {:ok, %{uid: "m1", status: "active", kyc_level: 100}}
      end)

      assert {:ok, %{uid: "m1", kyc_level: 100}} = Provider.provider().get_merchant("m1")
    end
  end

  describe "create_transaction/1" do
    test "returns transaction with payment url" do
      Frameworks.Payment.ProviderMock
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
               Provider.provider().create_transaction(%{total_amount: 10_000})

      assert is_binary(url)
    end
  end

  describe "get_transaction/1" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:get_transaction, fn "t1" ->
        {:ok, %{uid: "t1", status: "completed", payment_url: nil, amount: 5000}}
      end)

      assert {:ok, %{uid: "t1", status: "completed"}} = Provider.provider().get_transaction("t1")
    end
  end

  describe "create_withdrawal/2" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:create_withdrawal, fn "m1", %{amount: 1000} ->
        {:ok, %{uid: "w1", status: "created", amount: 1000}}
      end)

      assert {:ok, %{uid: "w1", amount: 1000}} =
               Provider.provider().create_withdrawal("m1", %{amount: 1000})
    end
  end

  describe "get_withdrawal/1" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:get_withdrawal, fn "w1" ->
        {:ok, %{uid: "w1", status: "completed", amount: 500}}
      end)

      assert {:ok, %{uid: "w1", status: "completed"}} = Provider.provider().get_withdrawal("w1")
    end
  end

  describe "create_multi_transaction/1" do
    test "delegates to configured provider" do
      Frameworks.Payment.ProviderMock
      |> expect(:create_multi_transaction, fn %{amount: 10_000} ->
        {:ok, %{uid: "mt1", status: "created"}}
      end)

      assert {:ok, %{uid: "mt1"}} =
               Provider.provider().create_multi_transaction(%{amount: 10_000})
    end
  end
end
