defmodule CoreWeb.UI.Responsive.BreakpointTest do
  use ExUnit.Case, async: true
  alias CoreWeb.UI.Responsive.Breakpoint

  describe "index_of/1" do
    test "return correct index" do
      assert Breakpoint.index_of(:min) == 0
      assert Breakpoint.index_of(:xs) == 1
      assert Breakpoint.index_of(:sm) == 2
      assert Breakpoint.index_of(:md) == 3
      assert Breakpoint.index_of(:lg) == 4
      assert Breakpoint.index_of(:xl) == 5
    end

    test "return nil for unknown breakpoints" do
      assert Breakpoint.index_of(:unknown) == nil
      assert Breakpoint.index_of(:bogus) == nil
    end
  end

  describe "compare/2" do
    test "smaller then" do
      assert Breakpoint.compare(:xs, :sm) < 0
    end

    test "larger than" do
      assert Breakpoint.compare(:xl, :md) > 0
    end

    test "equal to" do
      assert Breakpoint.compare(:sm, :sm) == 0
    end
  end

  describe "up_from/2" do
    test "true" do
      assert Breakpoint.up_from?(:xs, :xs)
      assert Breakpoint.up_from?(:xs, :sm)
      assert Breakpoint.up_from?(:xs, :xl)
    end

    test "false" do
      assert not Breakpoint.up_from?(:sm, :xs)
      assert not Breakpoint.up_from?(:lg, :md)
    end
  end

  describe "value/3" do
    test "single breakpoint" do
      assert Breakpoint.value({:sm, 0}, "base_value", md: "break_value-md") == "base_value"
      assert Breakpoint.value({:md, 0}, "base_value", md: "break_value-md") == "break_value-md"
      assert Breakpoint.value({:lg, 0}, "base_value", md: "break_value-md") == "break_value-md"
    end

    test "multiple breakpoints" do
      assert Breakpoint.value({:sm, 30}, "base_value", md: "break_value-md", xl: "break_value-xl") ==
               "base_value"

      assert Breakpoint.value({:md, 10}, "base_value", md: "break_value-md", xl: "break_value-xl") ==
               "break_value-md"

      assert Breakpoint.value({:lg, 90}, "base_value", md: "break_value-md", xl: "break_value-xl") ==
               "break_value-md"

      assert Breakpoint.value({:xl, -1}, "base_value", md: "break_value-md", xl: "break_value-xl") ==
               "break_value-xl"
    end

    test "single breakpoint with single percentage break" do
      assert Breakpoint.value({:sm, 40}, "base_value", sm: %{50 => "break_value-sm-50"}) ==
               "base_value"

      assert Breakpoint.value({:sm, 50}, "base_value", sm: %{50 => "break_value-sm-50"}) ==
               "break_value-sm-50"

      assert Breakpoint.value({:sm, 60}, "base_value", sm: %{50 => "break_value-sm-50"}) ==
               "break_value-sm-50"
    end

    test "single breakpoint with multiple percentage breaks" do
      assert Breakpoint.value({:sm, 0}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"}
             ) == "base_value"

      assert Breakpoint.value({:sm, 40}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"}
             ) == "break_value-sm-10"

      assert Breakpoint.value({:sm, 50}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"}
             ) == "break_value-sm-50"

      assert Breakpoint.value({:sm, 70}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"}
             ) == "break_value-sm-50"
    end

    test "multiple breakpoints with multiple percentage breaks" do
      assert Breakpoint.value({:sm, 20}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"},
               lg: %{50 => "break_value-lg-50"}
             ) == "break_value-sm-10"

      assert Breakpoint.value({:sm, 60}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"},
               lg: %{50 => "break_value-lg-50"}
             ) == "break_value-sm-50"

      assert Breakpoint.value({:lg, 10}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"},
               lg: %{50 => "break_value-lg-50"}
             ) == "break_value-sm-50"

      assert Breakpoint.value({:lg, 70}, "base_value",
               sm: %{10 => "break_value-sm-10", 50 => "break_value-sm-50"},
               lg: %{50 => "break_value-lg-50"}
             ) == "break_value-lg-50"
    end
  end

  describe "value_for_percentage/3" do
    test "test 100" do
      assert Breakpoint.value_for_percentage(%{0 => "0", 50 => "50", 100 => "100"}, 20, -1) == "0"

      assert Breakpoint.value_for_percentage(%{0 => "0", 50 => "50", 100 => "100"}, 70, -1) ==
               "50"

      assert Breakpoint.value_for_percentage(%{0 => "0", 50 => "50", 100 => "100"}, 100, -1) ==
               "100"
    end
  end

  describe "percentage/3" do
    test "test correct percentages" do
      assert Breakpoint.percentage(1000, 800, 1000) == 100
      assert Breakpoint.percentage(900, 800, 1000) == 50
      assert Breakpoint.percentage(850, 800, 1000) == 25
      assert Breakpoint.percentage(800, 800, 1000) == 0
    end

    test "test incorrect percentages" do
      assert_raise FunctionClauseError, fn -> Breakpoint.percentage(1200, 800, 1000) end
      assert_raise FunctionClauseError, fn -> Breakpoint.percentage(700, 800, 1000) end
      assert_raise FunctionClauseError, fn -> Breakpoint.percentage(850, 1100, 1000) end
    end
  end

  describe "breakpoint/3" do
    test "test breakpoints for several widths" do
      assert Breakpoint.breakpoint(%{"width" => 0}) == {:min, 0}
      assert Breakpoint.breakpoint(%{"width" => 320}) == {:xs, 0}
      assert Breakpoint.breakpoint(%{"width" => 640}) == {:sm, 0}
      assert Breakpoint.breakpoint(%{"width" => 1024}) == {:lg, 0}
      assert Breakpoint.breakpoint(%{"width" => 1152}) == {:lg, 50}
      assert Breakpoint.breakpoint(%{"width" => 1279}) == {:lg, 100}
      assert Breakpoint.breakpoint(%{"width" => 1280}) == {:xl, 0}
    end
  end

  describe "zip_shift_left/1" do
    test "zip shifted enum" do
      assert Breakpoint.zip_shift_left([:a, :b, :c, :d]) == [{:a, :b}, {:b, :c}, {:c, :d}]
    end
  end

  describe "remove_first/1" do
    test "removed last element of the given list" do
      assert Breakpoint.remove_first([]) == []
      assert Breakpoint.remove_first([:a]) == []
      assert Breakpoint.remove_first([:a, :b]) == [:b]
      assert Breakpoint.remove_first([:a, :b, :c]) == [:b, :c]
    end
  end
end
