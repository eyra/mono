defmodule Systems.Advert.ModelTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Advert

  describe "adverts" do
    alias Systems.Advert
    alias Core.{Factories, Authorization}

    test "list/1 returns all adverts" do
      advert = Factories.insert!(:advert)
      assert Advert.Public.list() |> Enum.find(&(&1.id == advert.id))
    end

    test "list/1 allows excluding a list of ids" do
      adverts = 0..3 |> Enum.map(fn _ -> Factories.insert!(:advert) end)
      {excluded_advert, expected_result} = List.pop_at(adverts, 1)

      advert_ids =
        Advert.Public.list(exclude: [excluded_advert.id])
        |> Enum.map(& &1.id)
        |> MapSet.new()

      expected_ids = expected_result |> Enum.map(& &1.id) |> MapSet.new()

      assert MapSet.subset?(expected_ids, advert_ids)
    end

    test "list_owned_adverts/1 returns only studies that are owned by the user" do
      _not_owned = Factories.insert!(:advert)
      researcher = Factories.insert!(:creator)
      submission = Factories.insert!(:pool_submission)
      owned = Factories.insert!(:advert, %{submission: submission})
      :ok = Authorization.assign_role(researcher, owned, :owner)
      assert Advert.Public.list_owned_adverts(researcher) |> Enum.map(& &1.id) == [owned.id]
    end

    test "get!/1 returns the advert with given id" do
      advert = Factories.insert!(:advert)
      assert Advert.Public.get!(advert.id) != nil
    end

    test "create/1 with valid data creates a advert" do
      submission = Factories.insert!(:pool_submission)
      promotion = Factories.insert!(:promotion)
      assignment = Factories.insert!(:assignment)
      researcher = Factories.insert!(:creator)
      auth_node = Factories.insert!(:auth_node)

      assert {:ok, %Advert.Model{}} =
               Advert.Public.create(promotion, assignment, submission, researcher, auth_node)

      assert_signal_dispatched({:advert, :created})
    end

    test "delete/1 deletes the advert" do
      advert = Factories.insert!(:advert)
      assert {:ok, _} = Advert.Public.delete(advert.id)
      assert_raise Ecto.NoResultsError, fn -> Advert.Public.get!(advert.id) end
    end

    test "change/1 returns a advert changeset" do
      advert = Factories.insert!(:advert)
      assert %Ecto.Changeset{} = Advert.Public.change(advert)
    end

    test "add_owner!/2 grants a user ownership over a advert" do
      researcher_1 = Factories.insert!(:creator)
      researcher_2 = Factories.insert!(:creator)
      submission = Factories.insert!(:pool_submission)
      advert = Factories.insert!(:advert, %{submission: submission})
      :ok = Authorization.assign_role(researcher_1, advert, :owner)
      # The second researcher is not the owner of the advert
      assert Advert.Public.list_owned_adverts(researcher_2) == []
      Advert.Public.add_owner!(advert, researcher_2)
      # The second researcher is now an owner of the advert
      assert Advert.Public.list_owned_adverts(researcher_2) |> Enum.map(& &1.id) == [
               advert.id
             ]
    end

    test "assign_owners/2 adds or removes a users ownership of a advert" do
      researcher_1 = Factories.insert!(:creator)
      researcher_2 = Factories.insert!(:creator)
      submission = Factories.insert!(:pool_submission)
      advert = Factories.insert!(:advert, %{submission: submission})
      :ok = Authorization.assign_role(researcher_1, advert, :owner)
      # The second researcher is not the owner of the advert
      assert Advert.Public.list_owned_adverts(researcher_2) == []
      Advert.Public.assign_owners(advert, [researcher_2])
      # The second researcher is now an owner of the advert
      assert Advert.Public.list_owned_adverts(researcher_2) |> Enum.map(& &1.id) == [
               advert.id
             ]

      # The original owner can no longer claim ownership
      assert Advert.Public.list_owned_adverts(researcher_1) == []
    end

    test "list_owners/1 returns all users with ownership permission on the advert" do
      researcher_1 = Factories.insert!(:creator)
      researcher_2 = Factories.insert!(:creator)
      advert = Factories.insert!(:advert)
      :ok = Authorization.assign_role(researcher_1, advert, :owner)
      assert Advert.Public.list_owners(advert) |> Enum.map(& &1.id) == [researcher_1.id]
      Advert.Public.assign_owners(advert, [researcher_2])
      assert Advert.Public.list_owners(advert) |> Enum.map(& &1.id) == [researcher_2.id]
    end
  end
end
