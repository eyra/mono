defmodule Systems.Assignment.ExternalPanelControllerTest do
  use ExUnit.Case, async: true

  alias Systems.Assignment.AffiliateController, as: Controller

  describe "valid_id?/1" do
    test "positive integer" do
      assert Controller.valid_id?("1234567890")
    end

    test "negative integer" do
      assert Controller.valid_id?("-1234567890")
    end

    test "word" do
      assert Controller.valid_id?("AAP_NOOT_mies_1234")
    end

    test "space" do
      assert not Controller.valid_id?("AAP NOOT")
    end

    test "special" do
      "~ ` ! @ $ % ^ & * ( ) + = { } [ ] : | \\ ; \" ' < , > . ? /"
      |> String.split(" ")
      |> Enum.each(fn special ->
        assert not Controller.valid_id?(special)
      end)
    end

    test "max length 64" do
      assert Controller.valid_id?(
               "1234567890123456789012345678901234567890123456789012345678901234"
             )
    end

    test "too long 65" do
      assert not Controller.valid_id?(
               "12345678901234567890123456789012345678901234567890123456789012345"
             )
    end
  end
end
