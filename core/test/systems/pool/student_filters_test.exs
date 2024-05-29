defmodule Systems.Pool.StudentFiltersTest do
  use Core.DataCase, async: true

  alias Systems.{
    Budget,
    Student
  }

  describe "include?/2" do
    test "include with 3 supported filters" do
      student1 = Factories.insert!(:member, %{creator: false})
      student2 = Factories.insert!(:member, %{creator: false})
      student3 = Factories.insert!(:member, %{creator: false})

      currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)

      pool =
        Factories.insert!(:pool, %{
          name: "test_1234",
          director: :student,
          target: 60,
          currency: currency
        })

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)

      assert Student.Filters.include?(student1, [:passed], pool)
      assert Student.Filters.include?(student2, [:passed], pool) == false
      assert Student.Filters.include?(student3, [:passed], pool) == false

      assert Student.Filters.include?(student1, [:active], pool) == false
      assert Student.Filters.include?(student2, [:active], pool)
      assert Student.Filters.include?(student3, [:active], pool) == false

      assert Student.Filters.include?(student1, [:inactive], pool) == false
      assert Student.Filters.include?(student2, [:inactive], pool) == false
      assert Student.Filters.include?(student3, [:inactive], pool)
    end

    test "include with 1 unsupported filter" do
      student1 = Factories.insert!(:member, %{creator: false})
      student2 = Factories.insert!(:member, %{creator: false})
      student3 = Factories.insert!(:member, %{creator: false})

      currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)

      pool =
        Factories.insert!(:pool, %{
          name: "test_1234",
          director: :student,
          target: 60,
          currency: currency
        })

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)
      Budget.Factories.create_wallet(student3, currency, 0)

      assert Student.Filters.include?(student1, [:unknown], pool)
      assert Student.Filters.include?(student2, [:unknown], pool)
      assert Student.Filters.include?(student3, [:unknown], pool)
    end

    test "include with 1 unsupported and 1 supported filter" do
      student1 = Factories.insert!(:member, %{creator: false})
      student2 = Factories.insert!(:member, %{creator: false})
      student3 = Factories.insert!(:member, %{creator: false})

      currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)

      pool =
        Factories.insert!(:pool, %{
          name: "test_1234",
          director: :student,
          target: 60,
          currency: currency
        })

      Budget.Factories.create_wallet(student1, currency, 60)
      Budget.Factories.create_wallet(student2, currency, 30)
      Budget.Factories.create_wallet(student3, currency, 0)

      assert Student.Filters.include?(student1, [:passed, :unknown], pool)
      assert Student.Filters.include?(student2, [:passed, :unknown], pool) == false
      assert Student.Filters.include?(student3, [:passed, :unknown], pool) == false
    end
  end
end
