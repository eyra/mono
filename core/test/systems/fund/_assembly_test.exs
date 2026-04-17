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
end
