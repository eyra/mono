defmodule Systems.Advert.ModelTest do
  use Mica.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Advert

  describe "adverts" do
    alias Systems.Advert
    alias Mica.Factories

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

  describe "Leaf.info" do
    alias Systems.Fund

    setup do
      currency = Fund.Factories.create_currency("info_currency", :legal, "ƒ", 2)
      user = Mica.Factories.insert!(:member)
      {:ok, currency: currency, user: user}
    end

    defp info_for_assignment_status(%{currency: currency, user: user}, status) do
      fund = Fund.Factories.create_fund("info_#{status}", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund)
      advert.assignment |> Ecto.Changeset.change(status: status) |> Mica.Repo.update!()
      advert |> Ecto.Changeset.change(status: :online) |> Mica.Repo.update!()

      advert.id
      |> Advert.Public.get!(Advert.Model.preload_graph(:down))
      |> Frameworks.Concept.Leaf.info("UTC")
    end

    test "labels an online advert whose assignment is not published", context do
      assert info_for_assignment_status(context, :concept) ==
               ["test_pool", "Visible in Pool – study not published"]
    end

    test "labels an online advert with a published assignment as visible", context do
      assert info_for_assignment_status(context, :online) == ["test_pool", "Visible in Pool"]
    end

    test "labels an online advert with an idle assignment as visible", context do
      assert info_for_assignment_status(context, :idle) == ["test_pool", "Visible in Pool"]
    end
  end
end
