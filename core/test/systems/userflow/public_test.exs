defmodule Systems.Userflow.PublicTest do
  use Core.DataCase, async: true

  alias Systems.Userflow
  alias Systems.Userflow.Factories

  describe "get!/1" do
    test "returns userflow when it exists" do
      userflow = Factories.insert!(:userflow)
      found = Userflow.Public.get!(userflow.identifier)
      assert found.id == userflow.id
    end

    test "raises when userflow does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Userflow.Public.get!("non-existent")
      end
    end
  end

  describe "create/2" do
    test "creates userflow with valid attributes" do
      {:ok, userflow} = Userflow.Public.create("test-flow", "Test Flow")
      assert userflow.identifier == "test-flow"
      assert userflow.title == "Test Flow"
    end

    test "returns error with duplicate identifier" do
      {:ok, _} = Userflow.Public.create("test-flow", "Test Flow")

      {:error, changeset} = Userflow.Public.create("test-flow", "Another Flow")
      assert "has already been taken" in errors_on(changeset).identifier
    end
  end

  describe "add_step/4" do
    setup do
      {:ok, userflow: Factories.insert!(:userflow)}
    end

    test "adds step to userflow", %{userflow: userflow} do
      {:ok, step} = Userflow.Public.add_step(userflow, "step-1", 1, "group-1")
      step = Repo.preload(step, :userflow)
      assert step.identifier == "step-1"
      assert step.order == 1
      assert step.group == "group-1"
      assert step.userflow.id == userflow.id
    end

    test "returns error with duplicate identifier", %{userflow: userflow} do
      {:ok, _} = Userflow.Public.add_step(userflow, "step-1", 1, "group-1")

      assert_raise Ecto.ConstraintError, fn ->
        Userflow.Public.add_step(userflow, "step-1", 2, "group-1")
      end
    end

    test "returns error with duplicate order", %{userflow: userflow} do
      {:ok, _} = Userflow.Public.add_step(userflow, "step-1", 1, "group-1")

      assert_raise Ecto.ConstraintError, fn ->
        Userflow.Public.add_step(userflow, "step-2", 1, "group-1")
      end
    end
  end

  describe "mark_visited/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Factories.insert!(:userflow)
      {:ok, step} = Userflow.Public.add_step(userflow, "step-1", 1, "group-1")
      {:ok, user: user, step: step}
    end

    test "creates progress when not visited", %{user: user, step: step} do
      {:ok, progress} = Userflow.Public.mark_visited(user.id, step.id)
      progress = Repo.preload(progress, [:user, :step])
      assert progress.user.id == user.id
      assert progress.step.id == step.id
      assert progress.visited_at
    end

    test "updates progress when already visited", %{user: user, step: step} do
      {:ok, first_progress} = Userflow.Public.mark_visited(user.id, step.id)
      # Ensure different timestamp
      Process.sleep(1000)
      {:ok, updated_progress} = Userflow.Public.mark_visited(user.id, step.id)
      assert updated_progress.id == first_progress.id
      assert updated_progress.visited_at > first_progress.visited_at
    end
  end

  describe "next_step/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Factories.insert_complete_userflow!()
      {:ok, user: user, userflow: userflow}
    end

    test "returns first step when no progress exists", %{user: user, userflow: userflow} do
      next_step = Userflow.Public.next_step(userflow.identifier, user.id)
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)
      assert next_step.id == first_step.id
    end

    test "returns nil when all steps completed", %{user: user} do
      userflow = Factories.insert_userflow_with_progress!(user)
      assert nil == Userflow.Public.next_step(userflow.identifier, user.id)
    end
  end

  describe "finished?/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Factories.insert_complete_userflow!()
      {:ok, user: user, userflow: userflow}
    end

    test "returns false when no progress exists", %{user: user, userflow: userflow} do
      refute Userflow.Public.finished?(userflow.identifier, user.id)
    end

    test "returns true when all steps completed", %{user: user} do
      userflow = Factories.insert_userflow_with_progress!(user)
      assert Userflow.Public.finished?(userflow.identifier, user.id)
    end
  end

  describe "steps_by_group/1" do
    test "returns steps grouped by group field" do
      userflow = Factories.insert_complete_userflow!()
      groups = Userflow.Public.steps_by_group(userflow.identifier)

      assert map_size(groups) == 2
      assert Enum.all?(Map.keys(groups), &(&1 =~ ~r/group-\d+/))

      for {_group, steps} <- groups do
        assert is_list(steps)
        assert Enum.all?(steps, &(&1.userflow_id == userflow.id))
        orders = Enum.map(steps, & &1.order)
        assert orders == Enum.sort(orders)
      end
    end
  end

  describe "get_user_progress/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Factories.insert_userflow_with_progress!(user)
      {:ok, user: user, userflow: userflow}
    end

    test "returns all progress for user in userflow", %{user: user, userflow: userflow} do
      progress =
        Userflow.Public.get_user_progress(user.id, userflow.id)
        |> Repo.preload([:user, step: :userflow])

      assert length(progress) == length(userflow.steps)
      assert Enum.all?(progress, &(&1.user.id == user.id))
      assert Enum.all?(progress, &(&1.step.userflow.id == userflow.id))
    end

    test "returns empty list when no progress exists", %{userflow: userflow} do
      other_user = Core.Factories.insert!(:member)
      assert [] == Userflow.Public.get_user_progress(other_user.id, userflow.id)
    end
  end
end
