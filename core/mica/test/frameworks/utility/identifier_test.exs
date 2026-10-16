defmodule Frameworks.Utility.IdentifierTest do
  use ExUnit.Case

  alias Frameworks.Utility.Identifier

  describe("get_attribute/2") do
    test "success: unknown attribute" do
      assert "1" = Identifier.get_attribute(["x=1", "y=2", "z=3"], "x")
    end

    test "failed: unknown attribute" do
      assert is_nil(Identifier.get_attribute(["x=1", "y=2", "z=3"], "a"))
    end

    test "failed: no value" do
      assert is_nil(Identifier.get_attribute(["x", "y=2", "z=3"], "x"))
    end
  end

  describe("get_attribute!/2") do
    test "success: unknown attribute" do
      assert "1" = Identifier.get_attribute!(["x=1", "y=2", "z=3"], "x")
    end

    test "failed: unknown attribute" do
      assert_raise ArgumentError, fn ->
        Identifier.get_attribute!(["x=1", "y=2", "z=3"], "a")
      end
    end
  end
end
