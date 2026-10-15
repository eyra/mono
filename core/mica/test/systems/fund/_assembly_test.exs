defmodule Systems.Fund.AssemblyTest do
  use Core.DataCase

  alias Systems.Fund

  describe "get_or_create_euro/0" do
    test "creates euro currency when it doesn't exist" do
      assert Fund.Public.get_currency_by_name("euro") == nil

      currency = Fund.Assembly.get_or_create_euro()

      assert %Fund.CurrencyModel{
               name: "euro",
               type: :legal,
               decimal_scale: 2
             } = currency

      assert currency.label_bundle != nil
    end

    test "returns existing euro currency when it exists" do
      first_currency = Fund.Assembly.get_or_create_euro()
      second_currency = Fund.Assembly.get_or_create_euro()

      assert first_currency.id == second_currency.id
    end

    test "euro currency has correct label bundle items" do
      currency = Fund.Assembly.get_or_create_euro()
      currency = Repo.preload(currency, label_bundle: :items)

      locales = Enum.map(currency.label_bundle.items, & &1.locale)
      assert "en" in locales
      assert "nl" in locales

      for item <- currency.label_bundle.items do
        assert item.text =~ "%{amount}"
      end
    end
  end

  describe "get_or_create/1" do
    test ":EUR maps to the \"euro\" currency (ledger atom -> friendly name)" do
      assert Fund.Public.get_currency_by_name("euro") == nil

      currency = Fund.Assembly.get_or_create(:EUR)

      assert %Fund.CurrencyModel{name: "euro", type: :legal, decimal_scale: 2} = currency
    end

    test ":EUR resolves to the same row as get_or_create_euro/0 (no \"eur\" vs \"euro\" mismatch)" do
      euro = Fund.Assembly.get_or_create_euro()
      via_atom = Fund.Assembly.get_or_create(:EUR)

      assert euro.id == via_atom.id
      assert Fund.Public.get_currency_by_name("eur") == nil
    end

    test ":USD maps to the \"dollar\" currency" do
      currency = Fund.Assembly.get_or_create(:USD)

      assert %Fund.CurrencyModel{name: "dollar", type: :legal, decimal_scale: 2} = currency
    end

    test "is idempotent per currency" do
      assert Fund.Assembly.get_or_create(:EUR).id == Fund.Assembly.get_or_create(:EUR).id
      assert Fund.Assembly.get_or_create(:USD).id == Fund.Assembly.get_or_create(:USD).id
      refute Fund.Assembly.get_or_create(:EUR).id == Fund.Assembly.get_or_create(:USD).id
    end

    test "raises for an unknown currency atom" do
      assert_raise KeyError, fn -> Fund.Assembly.get_or_create(:GBP) end
    end
  end
end
