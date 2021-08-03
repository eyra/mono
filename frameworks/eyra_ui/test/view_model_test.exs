defmodule EyraUI.ViewModel.Test do
  use ExUnit.Case, async: true

  require EyraUI.ViewModel
  import EyraUI.ViewModel

  describe("test_defviewmodel/1") do
    test "handles default nil properly" do
      expr = quote do: defviewmodel(prop: nil)
      expanded = Macro.expand(expr, __ENV__)
      string = Macro.to_string(expanded)

      assert string =~ "defgetter([:prop], nil)"
      assert string =~ "defhas([:prop])"
      assert string =~ "defviewmodel(nil, [:prop])"
    end

    test "handles boolean properly" do
      expr = quote do: defviewmodel(prop?: true)
      expanded = Macro.expand(expr, __ENV__)
      string = Macro.to_string(expanded)

      assert string =~ "defgetter([:prop?], true)"
      assert string =~ "defhas([:prop?])"
      assert string =~ "defviewmodel(nil, [:prop?])"
    end

    test "handles multiple properties properly" do
      expr = quote do: defviewmodel(prop1: nil, prop2?: true)
      expanded = Macro.expand(expr, __ENV__)
      string = Macro.to_string(expanded)

      assert string =~ "defgetter([:prop1], nil)"
      assert string =~ "defhas([:prop1])"
      assert string =~ "defviewmodel(nil, [:prop1])"

      assert string =~ "defgetter([:prop2?], true)"
      assert string =~ "defhas([:prop2?])"
      assert string =~ "defviewmodel(nil, [:prop2?])"
    end

    test "handles nested properties properly" do
      expr = quote do: defviewmodel(parent: [child1: "child1", child2?: false])
      expanded = Macro.expand(expr, __ENV__)
      string = Macro.to_string(expanded)

      assert string =~ "defgetter([:parent], child1: \"child1\", child2?: false)"
      assert string =~ "defhas([:parent])"
      assert string =~ "defviewmodel([child1: \"child1\", child2?: false], [:parent])"
    end
  end

  describe("defgetter/2") do
    test "handles short path properly" do
      expr =
        defmodule DefGetterShortPath do
          defgetter([:prop], nil)
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "[prop: 2]"
    end

    test "handles longer path properly" do
      expr =
        defmodule DefGetterLongerPath do
          defgetter([:parent, :child, :grandchild], nil)
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "[parent_child_grandchild: 2]"
    end

    test "handles short path boolean properly" do
      expr =
        defmodule DefGetterShortPathBoolean do
          defgetter([:prop?], true)
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "[prop?: 2]"
    end
  end

  describe("defhas/1") do
    test "handles short path properly" do
      expr =
        defmodule DefHasShortPath do
          defhas([:prop])
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "{:has_prop?, 1}"
    end

    test "handles longer path properly" do
      expr =
        defmodule DefHasLongerPath do
          defhas([:parent, :child, :grandchild])
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "{:has_parent_child_grandchild?, 1}"
    end

    test "handles short path boolean properly" do
      expr =
        defmodule DefHasShortPathBoolean do
          defhas([:prop?])
        end

      string = expr |> Macro.expand(__ENV__) |> Macro.to_string()

      assert string =~ "{:has_prop?, 1}"
    end
  end
end
