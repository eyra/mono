defmodule Systems.Assignment.CurrencyHelpersTest do
  use ExUnit.Case, async: true

  alias Systems.Assignment.CurrencyHelpers

  describe "display_to_cents/1 — accepts either decimal separator" do
    test "parses a comma as decimal separator" do
      assert CurrencyHelpers.display_to_cents("1,50") == {:ok, 150}
    end

    test "parses a period as decimal separator" do
      assert CurrencyHelpers.display_to_cents("1.50") == {:ok, 150}
    end

    test "parses the Arabic decimal separator (U+066B)" do
      assert CurrencyHelpers.display_to_cents("1٫50") == {:ok, 150}
    end

    test "parses a whole-number value" do
      assert CurrencyHelpers.display_to_cents("42") == {:ok, 4200}
    end

    test "rounds a value with three fractional digits" do
      assert CurrencyHelpers.display_to_cents("1,345") == {:ok, 135}
    end

    test "treats an empty string as zero" do
      assert CurrencyHelpers.display_to_cents("") == {:ok, 0}
    end
  end

  describe "display_to_cents/1 — rejects invalid input" do
    test "rejects letters" do
      assert CurrencyHelpers.display_to_cents("not a number") == :error
    end

    test "rejects a value with multiple separators (thousands grouping)" do
      assert CurrencyHelpers.display_to_cents("1,000.50") == :error
    end

    test "rejects a value with a trailing separator" do
      assert CurrencyHelpers.display_to_cents("1,") == :error
    end

    test "rejects a value with a leading separator" do
      assert CurrencyHelpers.display_to_cents(",50") == :error
    end
  end

  describe "cents_to_display/1 in nl locale" do
    setup do
      Gettext.put_locale(CoreWeb.Gettext, "nl")
      :ok
    end

    test "renders a fractional amount with a comma" do
      assert CurrencyHelpers.cents_to_display(150) == "1,5"
    end

    test "renders a whole-euro amount without a decimal separator" do
      assert CurrencyHelpers.cents_to_display(4200) == "42"
    end

    test "renders nil as an empty string" do
      assert CurrencyHelpers.cents_to_display(nil) == ""
    end

    test "renders zero as an empty string" do
      assert CurrencyHelpers.cents_to_display(0) == ""
    end
  end

  describe "cents_to_display/1 in en locale" do
    setup do
      Gettext.put_locale(CoreWeb.Gettext, "en")
      :ok
    end

    test "renders a fractional amount with a period" do
      assert CurrencyHelpers.cents_to_display(150) == "1.5"
    end
  end
end
