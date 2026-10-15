defmodule Frameworks.Utility.ModuleTest do
  use ExUnit.Case

  alias Frameworks.Utility.Module

  describe("to_model/2") do
    test "success: naked model" do
      assert "assignment" = Module.to_model(Systems.Assignment.Model)
    end

    test "success: item model" do
      assert "assignment_info" = Module.to_model(Systems.Assignment.InfoModel)
    end

    test "failed: no model" do
      assert_raise ArgumentError, fn ->
        Module.to_model(Systems.Assignment.InfoForm)
      end
    end
  end
end
