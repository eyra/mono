defmodule Systems.Advert.ModelTest do
  use Core.DataCase

  import Frameworks.Signal.TestHelper

  alias Systems.Advert

  describe "adverts" do
    alias Core.Factories

    test "list/1 returns all adverts" do
      advert = Factories.insert!(:advert)
      assert Enum.any?(Advert.Public.list(), &(&1.id == advert.id))
    end

    test "list/1 allows excluding a list of ids" do
      adverts = Enum.map(0..3, fn _ -> Factories.insert!(:advert) end)
      {excluded_advert, expected_result} = List.pop_at(adverts, 1)

      advert_ids =
        [exclude: [excluded_advert.id]]
        |> Advert.Public.list()
        |> MapSet.new(& &1.id)

      expected_ids = MapSet.new(expected_result, & &1.id)

      assert MapSet.subset?(expected_ids, advert_ids)
    end

    test "get!/1 returns the advert with given id" do
      advert = Factories.insert!(:advert)
      assert Advert.Public.get!(advert.id)
    end

    test "create/1 with valid data creates a advert" do
      isolate_signals()

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
