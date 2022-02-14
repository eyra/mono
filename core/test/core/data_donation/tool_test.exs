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
  end
end
