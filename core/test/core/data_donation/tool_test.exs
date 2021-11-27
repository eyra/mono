defmodule Systems.DataDonation.ToolTest do
  use Core.DataCase, async: true
  alias Core.Factories

  alias Systems.{
    DataDonation
  }

  describe "store_results/2" do
    setup do
      {:ok, tool: Factories.insert!(:data_donation_tool), user: Factories.insert!(:member)}
    end

    test "create a new record with the given data", %{tool: tool, user: user} do
      data = DataDonation.ToolModel.store_results(tool, user, "some data")
      assert data.tool_id == tool.id
      assert data.user_id == user.id
      assert data.data == "some data"
    end
  end
end
