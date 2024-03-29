defmodule Systems.Student.CriteriaFiltersTest do
  use Core.DataCase, async: true
  alias Systems.Student.CriteriaFilters

  describe "include?/2" do
    test "include with nil filters, 2 codes: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], nil)
    end

    test "include with 0 filters, 2 codes: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], [])
    end

    test "include with 1 filter and 1 match: true" do
      assert CriteriaFilters.include?([:iba_1], [:iba])
    end

    test "include with 2 filters and 1 match: false" do
      assert not CriteriaFilters.include?([:iba_1], [:iba, :resit])
    end

    test "include with 2 filters, 2 codes and 1 match: false" do
      assert not CriteriaFilters.include?([:iba_1, :iba_1_h], [:iba, :bk])
    end

    test "include with 2 filters, 2 codes and 2 match: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], [:iba, :resit])
    end
  end
end
