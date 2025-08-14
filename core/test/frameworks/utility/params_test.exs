defmodule Frameworks.Utility.ParamsTest do
  use ExUnit.Case
  alias Frameworks.Utility.Params

  describe "parse_bool_param/3" do
    test "handles common cases" do
      assert Params.parse_bool_param(%{"key" => "true"}, "key") == true
      assert Params.parse_bool_param(%{"key" => "false"}, "key") == false
      assert Params.parse_bool_param(%{"key" => "1"}, "key") == true
      assert Params.parse_bool_param(%{"key" => true}, "key") == true
      assert Params.parse_bool_param(%{}, "key") == false
      assert Params.parse_bool_param(%{"key" => "invalid"}, "key") == false

      # Test specific parameter names
      assert Params.parse_bool_param(%{"add_to_panl" => "true"}, "add_to_panl") == true
      assert Params.parse_bool_param(%{}, "add_to_panl") == false
      assert Params.parse_bool_param(%{"creator" => "true"}, "creator") == true
      assert Params.parse_bool_param(%{}, "creator") == false
    end
  end
end
