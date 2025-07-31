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
    end
  end

  describe "convenience functions" do
    test "parse_add_to_panl/1" do
      assert Params.parse_add_to_panl(%{"add_to_panl" => "true"}) == true
      assert Params.parse_add_to_panl(%{}) == false
    end

    test "parse_creator/1" do
      assert Params.parse_creator(%{"creator" => "true"}) == true
      assert Params.parse_creator(%{}) == false
    end
  end
end
