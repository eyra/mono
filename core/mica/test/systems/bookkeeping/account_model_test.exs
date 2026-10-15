defmodule Systems.Bookkeeping.AccountModelTest do
  use Core.DataCase, async: true
  alias Systems.Bookkeeping.AccountModel

  describe "checksum/1" do
    for {type, id, expected} <- [{:money_box, 123, "R80LM4"}, {:wallet, 1122, "1LQEFB1"}] do
      test "makes a string from #{type}, #{id}" do
        assert AccountModel.checksum({unquote(type), unquote(id)}) == unquote(expected)
      end
    end
  end

  describe "valid_checksum?/2" do
    test "returns true for correct checksum" do
      checksum = AccountModel.checksum({:wallet, 987})
      assert AccountModel.valid_checksum?({:wallet, 987}, checksum)
    end

    test "returns false for invalid checksum" do
      checksum = AccountModel.checksum({:wallet, 987})
      refute AccountModel.valid_checksum?({:wallet, 887}, checksum)
    end
  end
end
