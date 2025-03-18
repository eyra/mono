defmodule Systems.Userflow.AssemblyTest do
  use Core.DataCase, async: true

  alias Systems.Userflow.Assembly

  describe "prepare_userflow/0" do
    test "creates userflow" do
      assert {:ok, _} = Assembly.create_userflow()
    end
  end
end
