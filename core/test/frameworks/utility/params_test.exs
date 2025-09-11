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

    test "parse_string_param for post_*_action" do
      assert Params.parse_string_param(
               %{"post_signin_action" => "add_to_panl"},
               "post_signin_action"
             ) ==
               "add_to_panl"

      assert Params.parse_string_param(%{}, "post_signin_action") == nil

      assert Params.parse_string_param(
               %{"post_signup_action" => "add_to_panl"},
               "post_signup_action"
             ) ==
               "add_to_panl"

      assert Params.parse_string_param(%{}, "post_signup_action") == nil
    end
  end
end
