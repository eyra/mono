defmodule Systems.Payment.Provider.LocalTest do
  @moduledoc """
  Pins the Local (dev/test) provider stub contract. The local payout
  happy-path relies on the stub always reporting a fully-verified merchant
  and an approved bank account so prepare_payout/1 reaches `:ok` without an
  OPP round-trip.
  """
  use ExUnit.Case, async: true

  alias Systems.Payment.Provider.Local

  describe "create_merchant/1" do
    test "returns a live, verified merchant" do
      assert {:ok, merchant} = Local.create_merchant(%{emailaddress: "a@b.c"})
      assert merchant.status == "live"
      assert merchant.compliance_status == "verified"
      assert is_binary(merchant.uid)
    end
  end

  describe "create_bank_account/2" do
    test "returns an approved bank account" do
      assert {:ok, %{status: "approved"} = ba} = Local.create_bank_account("m_1", %{})
      assert is_binary(ba.uid)
    end

    test "crashes on a non-binary merchant_uid (guard)" do
      assert_raise FunctionClauseError, fn -> Local.create_bank_account(nil, %{}) end
    end

    test "crashes on non-map attrs (guard)" do
      assert_raise FunctionClauseError, fn -> Local.create_bank_account("m_1", "nope") end
    end
  end

  describe "list_bank_accounts/1" do
    test "returns a non-empty list with an approved account" do
      assert {:ok, [%{status: "approved"} | _]} = Local.list_bank_accounts("m_1")
    end

    test "crashes on a non-binary merchant_uid (guard)" do
      assert_raise FunctionClauseError, fn -> Local.list_bank_accounts(nil) end
    end
  end
end
