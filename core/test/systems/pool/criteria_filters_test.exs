defmodule Systems.Pool.CriteriaFiltersTest do
  use Core.DataCase, async: true
  alias Systems.Pool.CriteriaFilters

  describe "include?/2" do
    test "include with nil filters, 2 codes: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], nil)
    end

    test "include with 0 filters, 2 codes: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], [])
    end

    test "include with 1 filter and 1 match: true" do
      assert CriteriaFilters.include?([:iba_1], [:year1])
    end

    test "include with 2 filters and 1 match: false" do
      assert not CriteriaFilters.include?([:iba_1], [:year1, :year2])
    end

    test "include with 2 filters, 2 codes and 1 match: false" do
      assert not CriteriaFilters.include?([:iba_1, :iba_1_h], [:year1, :year2])
    end

    test "include with 2 filters, 2 codes and 2 match: true" do
      assert CriteriaFilters.include?([:iba_1, :iba_1_h], [:year1, :resit])
    end
  end
end
