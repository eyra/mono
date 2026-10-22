defmodule Frameworks.Pixel.ViewModel.Test do
  use ExUnit.Case, async: true

  require Frameworks.Pixel.ViewModel
  import Frameworks.Pixel.ViewModel

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
      {:module, module, _, _} =
        defmodule DefGetterShortPath do
          defgetter([:prop], nil)
        end

      assert function_exported?(module, :prop, 2)
    end

    test "handles longer path properly" do
      {:module, module, _, _} =
        defmodule DefGetterLongerPath do
          defgetter([:parent, :child, :grandchild], nil)
        end

      assert function_exported?(module, :parent_child_grandchild, 2)
    end

    test "handles short path boolean properly" do
      {:module, module, _, _} =
        defmodule DefGetterShortPathBoolean do
          defgetter([:prop?], true)
        end

      assert function_exported?(module, :prop?, 2)
    end
  end

  describe("defhas/1") do
    test "handles short path properly" do
      {:module, module, _, _} =
        defmodule DefHasShortPath do
          defhas([:prop])
        end

      assert function_exported?(module, :has_prop?, 1)
    end

    test "handles longer path properly" do
      {:module, module, _, _} =
        defmodule DefHasLongerPath do
          defhas([:parent, :child, :grandchild])
        end

      assert function_exported?(module, :has_parent_child_grandchild?, 1)
    end

    test "handles short path boolean properly" do
      {:module, module, _, _} =
        defmodule DefHasShortPathBoolean do
          defhas([:prop?])
        end

      assert function_exported?(module, :has_prop?, 1)
    end
  end
end
