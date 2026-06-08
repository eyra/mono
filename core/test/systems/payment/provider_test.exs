defmodule Systems.Payment.ProviderTest do
  use Core.PaymentCase, async: true

  alias Systems.Payment.Transaction

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
      description = %Transaction.Description{
        platform: "Eyra Next",
        assignment: "Data Donation TikTok",
        participant_count: 100,
        amount_per_participant: 250
      }

      metadata = %Transaction.Metadata{
        contact_person: "Dr. Jane Smith",
        study_title: "TikTok Study",
        study_goal: "Analyze usage",
        participant_count: 100,
        amount_per_participant: 250
      }

      request = %Transaction.Request{
        merchant_uid: "m1",
        total_amount: 10_000,
        currency: :EUR,
        invoice_id: "NEXT-NL-0128",
        idempotence_key: "assignment=1,user=42,type=payment",
        description: description,
        metadata: metadata
      }

      ProviderMock
      |> expect(:create_transaction, fn ^request ->
        {:ok,
         %{
           uid: "t1",
           status: "created",
           payment_url: "https://pay.example.com/t1",
           amount: 10_000
         }}
      end)

      assert {:ok, %{uid: "t1", payment_url: url}} =
               ProviderMock.create_transaction(request)

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

  describe "create_withdrawal/4" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:create_withdrawal, fn "m1", :EUR, %{amount: 1000}, "payout=1" ->
        {:ok, %{uid: "w1", status: "created", amount: 1000}}
      end)

      assert {:ok, %{uid: "w1", amount: 1000}} =
               ProviderMock.create_withdrawal("m1", :EUR, %{amount: 1000}, "payout=1")
    end
  end

  describe "create_charge/4" do
    test "delegates to configured provider" do
      ProviderMock
      |> expect(:create_charge, fn "mer_platform", "mer_participant", 1000, "payout=1,type=charge" ->
        {:ok, %{uid: "chg1", status: "created", amount: 1000}}
      end)

      assert {:ok, %{uid: "chg1", amount: 1000}} =
               ProviderMock.create_charge("mer_platform", "mer_participant", 1000, "payout=1,type=charge")
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
end
