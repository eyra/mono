defmodule Systems.Budget.AccountStrategyTest do
  use Core.DataCase

  alias Systems.Budget.AccountStrategy

  describe "encode/1" do
    test "wallet" do
      assert AccountStrategy.encode({:wallet, "euro", 2345}) == "W2345/252SMHG"
    end

    test "fund" do
      assert AccountStrategy.encode({:fund, "fund"}) == "F/1N6PLRI"
    end

    test "unknown" do
      assert AccountStrategy.encode({:something, "unknown"}) == "?/2T38DCU"
    end
  end
end
