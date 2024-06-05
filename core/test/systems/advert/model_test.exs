defmodule Systems.Advert.ModelTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Advert

  describe "adverts" do
    alias Systems.Advert
    alias Core.Factories

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
  end
end
