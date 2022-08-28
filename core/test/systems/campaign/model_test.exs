defmodule Systems.Campaign.ModelTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Campaign

  describe "campaigns" do
    alias Systems.Campaign
    alias Core.{Factories, Authorization}

    test "list/1 returns all campaigns" do
      campaign = Factories.insert!(:campaign)
      assert Campaign.Context.list() |> Enum.find(&(&1.id == campaign.id))
    end

    test "list/1 allows excluding a list of ids" do
      campaigns = 0..3 |> Enum.map(fn _ -> Factories.insert!(:campaign) end)
      {excluded_campaign, expected_result} = List.pop_at(campaigns, 1)

      campaign_ids =
        Campaign.Context.list(exclude: [excluded_campaign.id])
        |> Enum.map(& &1.id)
        |> MapSet.new()

      expected_ids = expected_result |> Enum.map(& &1.id) |> MapSet.new()

      assert MapSet.subset?(expected_ids, campaign_ids)
    end

    test "list_owned_campaigns/1 returns only studies that are owned by the user" do
      _not_owned = Factories.insert!(:campaign)
      researcher = Factories.insert!(:researcher)
      owned = Factories.insert!(:campaign)
      :ok = Authorization.assign_role(researcher, owned, :owner)
      assert Campaign.Context.list_owned_campaigns(researcher) |> Enum.map(& &1.id) == [owned.id]
    end

    test "get!/1 returns the campaign with given id" do
      campaign = Factories.insert!(:campaign)
      assert Campaign.Context.get!(campaign.id) != nil
    end

    test "create/1 with valid data creates a campaign" do
      submission = Factories.insert!(:submission)
      promotion = Factories.insert!(:promotion)
      assignment = Factories.insert!(:assignment)
      researcher = Factories.insert!(:researcher)
      auth_node = Factories.insert!(:auth_node)

      assert {:ok, %Campaign.Model{}} =
               Campaign.Context.create(promotion, assignment, [submission], researcher, auth_node)

      assert_signal_dispatched(:campaign_created)
    end

    test "delete/1 deletes the campaign" do
      campaign = Factories.insert!(:campaign)
      assert {:ok, _} = Campaign.Context.delete(campaign.id)
      assert_raise Ecto.NoResultsError, fn -> Campaign.Context.get!(campaign.id) end
    end

    test "change/1 returns a campaign changeset" do
      campaign = Factories.insert!(:campaign)
      assert %Ecto.Changeset{} = Campaign.Context.change(campaign)
    end

    test "add_owner!/2 grants a user ownership over a campaign" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      campaign = Factories.insert!(:campaign)
      :ok = Authorization.assign_role(researcher_1, campaign, :owner)
      # The second researcher is not the owner of the campaign
      assert Campaign.Context.list_owned_campaigns(researcher_2) == []
      Campaign.Context.add_owner!(campaign, researcher_2)
      # The second researcher is now an owner of the campaign
      assert Campaign.Context.list_owned_campaigns(researcher_2) |> Enum.map(& &1.id) == [
               campaign.id
             ]
    end

    test "assign_owners/2 adds or removes a users ownership of a campaign" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      campaign = Factories.insert!(:campaign)
      :ok = Authorization.assign_role(researcher_1, campaign, :owner)
      # The second researcher is not the owner of the campaign
      assert Campaign.Context.list_owned_campaigns(researcher_2) == []
      Campaign.Context.assign_owners(campaign, [researcher_2])
      # The second researcher is now an owner of the campaign
      assert Campaign.Context.list_owned_campaigns(researcher_2) |> Enum.map(& &1.id) == [
               campaign.id
             ]

      # The original owner can no longer claim ownership
      assert Campaign.Context.list_owned_campaigns(researcher_1) == []
    end

    test "list_owners/1 returns all users with ownership permission on the campaign" do
      researcher_1 = Factories.insert!(:researcher)
      researcher_2 = Factories.insert!(:researcher)
      campaign = Factories.insert!(:campaign)
      :ok = Authorization.assign_role(researcher_1, campaign, :owner)
      assert Campaign.Context.list_owners(campaign) |> Enum.map(& &1.id) == [researcher_1.id]
      Campaign.Context.assign_owners(campaign, [researcher_2])
      assert Campaign.Context.list_owners(campaign) |> Enum.map(& &1.id) == [researcher_2.id]
    end
  end
end
