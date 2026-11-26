defmodule Mica.RepoTest do
  use Mica.DataCase

  alias Mica.Repo
  alias Mica.Factories
  alias Ecto.Multi
  alias Systems.Org

  describe "multi_update_guard/3" do
    setup do
      %{info: Factories.insert!(:assignment_info, %{subject_count: 1})}
    end

    test "passes when the model is up to date", %{info: info} do
      assert {:ok, %{"assignment_info_up_to_date?" => true}} =
               Multi.new()
               |> Repo.multi_update_guard(:assignment_info, info)
               |> Repo.commit()
    end

    test "returns an error for a stale model with an atom name", %{info: info} do
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}

      assert {:error, "assignment_info_up_to_date?",
              "Assignment_info is not up to date, preventing database change", _} =
               Multi.new()
               |> Repo.multi_update_guard(:assignment_info, stale)
               |> Repo.commit()
    end

    test "returns an error for a stale model with a string name", %{info: info} do
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}

      assert {:error, "info_up_to_date?", "Info is not up to date, preventing database change", _} =
               Multi.new()
               |> Repo.multi_update_guard("info", stale)
               |> Repo.commit()
    end
  end

  describe "multi_update/3" do
    test "does not update a stale model" do
      info = Factories.insert!(:assignment_info, %{subject_count: 1})
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}
      changeset = Ecto.Changeset.change(stale, subject_count: 2)

      assert {:error, "assignment_info_up_to_date?", _, _} =
               Multi.new()
               |> Repo.multi_update(:assignment_info, changeset)
               |> Repo.commit()

      assert %{subject_count: 1} = Repo.get!(Systems.Assignment.InfoModel, info.id)
    end
  end

  describe "after_commit/1" do
    defp register(multi, name) do
      test_pid = self()

      Multi.run(multi, name, fn _, _ ->
        {:ok, Repo.after_commit(fn -> send(test_pid, {:after_commit, name}) end)}
      end)
    end

    test "runs the functions in order once the transaction commits" do
      {:ok, _} =
        Multi.new()
        |> register(:first)
        |> register(:second)
        |> Repo.commit()

      assert {:messages, [{:after_commit, :first}, {:after_commit, :second}]} =
               Process.info(self(), :messages)
    end

    test "drops the functions when a step fails" do
      {:error, :fail, _, _} =
        Multi.new()
        |> register(:first)
        |> Multi.run(:fail, fn _, _ -> {:error, :rollback} end)
        |> Repo.commit()

      {:ok, _} = Repo.commit(Multi.new())

      refute_received {:after_commit, _}
    end

    test "drops the functions when a step raises" do
      assert_raise RuntimeError, fn ->
        Multi.new()
        |> register(:first)
        |> Multi.run(:raise, fn _, _ -> raise "rollback" end)
        |> Repo.commit()
      end

      {:ok, _} = Repo.commit(Multi.new())

      refute_received {:after_commit, _}
    end

    test "a nested commit runs its functions only after the outer commit" do
      {:ok, _} =
        Multi.new()
        |> register(:outer)
        |> Multi.run(:nested, fn _, _ ->
          result = Multi.new() |> register(:nested) |> Repo.commit()
          refute_received {:after_commit, _}
          result
        end)
        |> Repo.commit()

      assert_received {:after_commit, :outer}
      assert_received {:after_commit, :nested}
    end
  end

  describe "orphan?" do
    test "returns true if the entity is not referred to by any other entity" do
      node = Factories.insert!(:org_node, %{identifier: ["orphan_test_node"]})
      assert Repo.orphan?(node, ignore: [Org.LinkModel])
    end

    test "returns false if the Systems.Org.LinkModel association table is not ignored" do
      # Org.NodeModel -> Org.NodeModel goes through the Org.LinkModel association table.
      # By not ignoring the Org.LinkModel association table, a node with at least one link
      # will not be considered orphaned. The association table has a reference to this node.
      # This is a general phenomenon with association schemas.

      node1 = Factories.insert!(:org_node, %{identifier: ["orphan_test_node1"]})
      node2 = Factories.insert!(:org_node, %{identifier: ["orphan_test_node2"]})
      Factories.insert!(:org_link, %{from: node2, to: node1})

      assert not Repo.orphan?(node2, ignore: [])
    end

    test "returns false if the entity is referred to by another entity" do
      node1 = Factories.insert!(:org_node, %{identifier: ["orphan_test_node1"]})
      Org.Public.add_user(node1, Factories.insert!(:member))

      node2 = Factories.insert!(:org_node, %{identifier: ["orphan_test_node2"]})
      Factories.insert!(:org_link, %{from: node2, to: node1})

      node3 = Factories.insert!(:org_node, %{identifier: ["orphan_test_node3"]})

      assert not Repo.orphan?(node1, ignore: [Org.LinkModel])
      assert Repo.orphan?(node2, ignore: [Org.LinkModel])
      assert Repo.orphan?(node3, ignore: [Org.LinkModel])
    end
  end
end
