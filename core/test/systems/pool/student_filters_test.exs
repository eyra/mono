defmodule Systems.Pool.StudentFiltersTest do
  use Core.DataCase, async: true
  alias Systems.Pool.StudentFilters
  alias Systems.Budget

  describe "include?/2" do
    test "include with 3 supported filters" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})
      student3 = Factories.insert!(:member, %{student: true})

      currency = Budget.Factories.create_currency("test_1234", "ƒ", 2)
      pool = Factories.insert!(:pool, %{name: "test_1234", target: 60, currency: currency})

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)

      assert StudentFilters.include?(student1, [:passed], pool)
      assert StudentFilters.include?(student2, [:passed], pool) == false
      assert StudentFilters.include?(student3, [:passed], pool) == false

      assert StudentFilters.include?(student1, [:active], pool) == false
      assert StudentFilters.include?(student2, [:active], pool)
      assert StudentFilters.include?(student3, [:active], pool) == false

      assert StudentFilters.include?(student1, [:inactive], pool) == false
      assert StudentFilters.include?(student2, [:inactive], pool) == false
      assert StudentFilters.include?(student3, [:inactive], pool)
    end

    test "include with 1 unsupported filter" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})
      student3 = Factories.insert!(:member, %{student: true})

      currency = Budget.Factories.create_currency("test_1234", "ƒ", 2)
      pool = Factories.insert!(:pool, %{name: "test_1234", target: 60, currency: currency})

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)
      Budget.Factories.create_wallet(student3, currency, 0)

      assert StudentFilters.include?(student1, [:unknown], pool)
      assert StudentFilters.include?(student2, [:unknown], pool)
      assert StudentFilters.include?(student3, [:unknown], pool)
    end

    test "include with 1 unsupported and 1 supported filter" do
      student1 = Factories.insert!(:member, %{student: true})
      student2 = Factories.insert!(:member, %{student: true})
      student3 = Factories.insert!(:member, %{student: true})

      currency = Budget.Factories.create_currency("test_1234", "ƒ", 2)
      pool = Factories.insert!(:pool, %{name: "test_1234", target: 60, currency: currency})

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)
      Budget.Factories.create_wallet(student3, currency, 0)

      assert StudentFilters.include?(student1, [:passed, :unknown], pool)
      assert StudentFilters.include?(student2, [:passed, :unknown], pool) == false
      assert StudentFilters.include?(student3, [:passed, :unknown], pool) == false
    end
  end
end
