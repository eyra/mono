defmodule Systems.Userflow.ModelTest do
  use Core.DataCase, async: true

  alias Systems.Userflow

  describe "changeset/2" do
    test "validates required fields" do
      changeset = Userflow.Model.changeset(%Userflow.Model{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).identifier
      assert "can't be blank" in errors_on(changeset).title
    end

    test "validates with valid attributes" do
      attrs = %{
        identifier: "test-userflow",
        title: "Test Userflow"
      }

      changeset = Userflow.Model.changeset(%Userflow.Model{}, attrs)
      assert changeset.valid?
    end

    test "enforces unique identifier constraint" do
      attrs = %{identifier: "unique-flow", title: "Test Flow"}
      {:ok, _} = Userflow.Model.changeset(%Userflow.Model{}, attrs) |> Repo.insert()

      {:error, changeset} = Userflow.Model.changeset(%Userflow.Model{}, attrs) |> Repo.insert()
      assert "has already been taken" in errors_on(changeset).identifier
    end
  end

  describe "finished?/2" do
    setup do
      user = Core.Factories.insert!(:member)
      {:ok, user: user}
    end

    test "returns true when all steps have progress for the user", %{user: user} do
      userflow = Userflow.Factories.insert_userflow_with_progress!(user)
      assert Userflow.Model.finished?(userflow, user.id)
    end

    test "returns false when not all steps have progress", %{user: user} do
      userflow = Userflow.Factories.insert_complete_userflow!()
      userflow = Repo.preload(userflow, steps: [:progress])
      refute Userflow.Model.finished?(userflow, user.id)
    end

    test "returns false when some steps have progress", %{user: user} do
      userflow = Userflow.Factories.insert_complete_userflow!()
      userflow = Repo.preload(userflow, :steps)
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      # Add progress only to the first step
      Userflow.Factories.insert!(
        :progress,
        %{
          user_id: user.id,
          step_id: first_step.id,
          visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      )

      userflow = Repo.preload(userflow, steps: [:progress])
      refute Userflow.Model.finished?(userflow, user.id)
    end
  end

  describe "next_step/2" do
    setup do
      user = Core.Factories.insert!(:member)
      {:ok, user: user}
    end

    test "returns nil when all steps are completed", %{user: user} do
      userflow = Userflow.Factories.insert_userflow_with_progress!(user)
      assert nil == Userflow.Model.next_step(userflow, user.id)
    end

    test "returns the first step when no progress exists", %{user: user} do
      userflow = Userflow.Factories.insert_complete_userflow!()
      userflow = Repo.preload(userflow, steps: [:progress])
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      assert first_step.id == Userflow.Model.next_step(userflow, user.id).id
    end

    test "returns the next incomplete step", %{user: user} do
      userflow = Userflow.Factories.insert_complete_userflow!()
      userflow = Repo.preload(userflow, :steps)
      [first_step, second_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      # Complete first step
      Userflow.Factories.insert!(
        :progress,
        %{
          user_id: user.id,
          step_id: first_step.id,
          visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      )

      userflow = Repo.preload(userflow, steps: [:progress])
      assert second_step.id == Userflow.Model.next_step(userflow, user.id).id
    end
  end

  describe "steps_by_group/1" do
    test "groups steps by their group attribute" do
      userflow = Userflow.Factories.insert_complete_userflow!()
      userflow = Repo.preload(userflow, steps: :userflow)
      groups = Userflow.Model.steps_by_group(userflow)

      assert map_size(groups) == 2
      assert Enum.all?(Map.keys(groups), &(&1 =~ ~r/group-\d+/))

      for {_group, steps} <- groups do
        assert is_list(steps)
        assert Enum.all?(steps, &(&1.userflow.id == userflow.id))
      end
    end

    test "returns empty map when userflow has no steps" do
      userflow = Userflow.Factories.insert!(:userflow)
      userflow = %{userflow | steps: []}

      assert %{} == Userflow.Model.steps_by_group(userflow)
    end

    test "maintains step order within groups" do
      userflow = Userflow.Factories.insert_complete_userflow!()
      groups = Userflow.Model.steps_by_group(userflow)

      for {_group, steps} <- groups do
        orders = Enum.map(steps, & &1.order)
        assert orders == Enum.sort(orders)
      end
    end
  end

  describe "preload_graph/1" do
    test "returns correct preload graph for :down direction" do
      assert [steps: [progress: []]] == Userflow.Model.preload_graph(:down)
    end

    test "returns correct preload graph for :up direction" do
      assert [] == Userflow.Model.preload_graph(:up)
    end
  end
end
