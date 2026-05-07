defmodule Systems.Payment.PartnerFeeTest do
  use ExUnit.Case, async: false

  alias Systems.Payment

  setup do
    original = Application.get_env(:core, Payment.Provider.OPP, [])

    on_exit(fn ->
      Application.put_env(:core, Payment.Provider.OPP, original)
    end)

    %{original: original}
  end

  describe "partner_fee_percentage/0" do
    test "returns 0 when not configured", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.delete(original, :partner_fee_percentage)
      )

      assert Payment.Public.partner_fee_percentage() == 0
    end

    test "returns configured value", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.put(original, :partner_fee_percentage, 5)
      )

      assert Payment.Public.partner_fee_percentage() == 5
    end
  end

  describe "partner_fee_amount/1" do
    test "returns 0 when percentage is 0", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.put(original, :partner_fee_percentage, 0)
      )

      assert Payment.Public.partner_fee_amount(10_000) == 0
    end

    test "returns rounded-down percentage of base", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.put(original, :partner_fee_percentage, 5)
      )

      assert Payment.Public.partner_fee_amount(10_000) == 500
    end

    test "truncates fractional cents (integer division)", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.put(original, :partner_fee_percentage, 3)
      )

      assert Payment.Public.partner_fee_amount(199) == 5
    end

    test "returns 0 for zero base", %{original: original} do
      Application.put_env(
        :core,
        Payment.Provider.OPP,
        Keyword.put(original, :partner_fee_percentage, 10)
      )

      assert Payment.Public.partner_fee_amount(0) == 0
    end

    test "crashes on negative base" do
      assert_raise FunctionClauseError, fn ->
        Payment.Public.partner_fee_amount(-100)
      end
    end
  end
end
