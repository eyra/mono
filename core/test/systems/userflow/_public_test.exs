defmodule Systems.Userflow.PublicTest do
  use Core.DataCase, async: true

  alias Systems.Userflow
  alias Systems.Userflow

  describe "get_userflow!/1" do
    test "returns userflow when it exists" do
      userflow = Userflow.Factory.insert(:userflow)
      found = Userflow.Public.get_userflow!(userflow.id)
      assert found.id == userflow.id
    end

    test "raises when userflow does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Userflow.Public.get_userflow!(1)
      end
    end
  end

  describe "add_step/4" do
    setup do
      {:ok, userflow: Userflow.Factory.insert(:userflow)}
    end

    test "adds step to userflow", %{userflow: userflow} do
      {:ok, step} = Userflow.Public.add_step(userflow, "group-1")

      step = Repo.preload(step, :userflow)
      assert step.order == 1
      assert step.group == "group-1"
      assert step.userflow.id == userflow.id
    end

    test "adds second step to userflow", %{userflow: userflow} do
      {:ok, _} = Userflow.Public.add_step(userflow, "group-1")
      {:ok, _} = Userflow.Public.add_step(userflow, "group-1")

      userflow = Repo.preload(userflow, :steps)
      [first_step, second_step] = Enum.sort_by(userflow.steps, & &1.order)
      assert first_step.order == 1
      assert second_step.order == 2
    end
  end

  describe "mark_visited/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.insert(:userflow)
      {:ok, step} = Userflow.Public.add_step(userflow, "group-1")
      {:ok, user: user, step: step}
    end

    test "creates progress when not visited", %{user: user, step: step} do
      {:ok, %{progress: progress}} = Userflow.Public.mark_visited(step, user)
      assert progress.user.id == user.id
      assert progress.step.id == step.id
    end
  end

  describe "next_step/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow()
      {:ok, user: user, userflow: userflow}
    end

    test "returns first step when no progress exists", %{user: user, userflow: userflow} do
      next_step = Userflow.Public.next_step(userflow, user.id)
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)
      assert next_step.id == first_step.id
    end

    test "returns nil when all steps completed", %{user: user} do
      userflow = Userflow.Factory.userflow_finished(user)
      assert nil == Userflow.Public.next_step(userflow, user.id)
    end
  end

  describe "finished?/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow()
      {:ok, user: user, userflow: userflow}
    end

    test "returns false when no progress exists", %{user: user, userflow: userflow} do
      refute Userflow.Public.finished?(userflow, user.id)
    end

    test "returns true when all steps completed", %{user: user} do
      userflow = Userflow.Factory.userflow_finished(user)
      assert Userflow.Public.finished?(userflow, user.id)
    end
  end

  describe "steps_by_group/1" do
    test "returns steps grouped by group field" do
      userflow = Userflow.Factory.userflow()
      groups = Userflow.Public.steps_by_group(userflow)

      assert Enum.all?(Map.keys(groups), &(&1 =~ ~r/group-\d+/))

      for {_group, steps} <- groups do
        assert is_list(steps)
        assert Enum.all?(steps, &(&1.userflow_id == userflow.id))
        orders = Enum.map(steps, & &1.order)
        assert orders == Enum.sort(orders)
      end
    end
  end

  describe "get_progress/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow_finished(user)
      {:ok, user: user, userflow: userflow}
    end

    test "returns all progress for user in userflow", %{user: user, userflow: userflow} do
      progress =
        Userflow.Public.list_progress(userflow, user.id)
        |> Repo.preload([:user, step: :userflow])

      assert length(progress) == length(userflow.steps)
      assert Enum.all?(progress, &(&1.user.id == user.id))
      assert Enum.all?(progress, &(&1.step.userflow.id == userflow.id))
    end

    test "returns empty list when no progress exists", %{userflow: userflow} do
      other_user = Core.Factories.insert!(:member)
      assert [] == Userflow.Public.list_progress(userflow, other_user.id)
    end
  end

  describe "move_step/2" do
    setup do
      userflow = Userflow.Factory.userflow()

      {:ok, userflow: userflow}
    end

    test "moves a step up in the order", %{userflow: userflow} do
      step1 = Enum.at(userflow.steps, 0)
      step2 = Enum.at(userflow.steps, 1)

      {:ok, result} = Userflow.Public.move_step(step2, :up)

      # Verify the steps have swapped positions
      updated_step = result.userflow_step
      updated_previous_step = result.previous_step_updated

      assert updated_step.order == step1.order
      assert updated_previous_step.order == step2.order
      assert updated_step.id == step2.id
      assert updated_previous_step.id == step1.id
    end

    test "fails when trying to move the first step up", %{userflow: userflow} do
      step1 = Enum.at(userflow.steps, 0)
      # The first step has no previous step
      assert {:error, :previous_step, :no_previous_step, _} =
               Userflow.Public.move_step(step1, :up)
    end

    test "correctly updates the database with new positions", %{userflow: userflow} do
      step2 = Enum.at(userflow.steps, 1)
      step3 = Enum.at(userflow.steps, 2)

      {:ok, _result} = Userflow.Public.move_step(step3, :up)

      # Reload steps from database to verify changes persisted
      reloaded_step2 = Repo.get!(Userflow.StepModel, step2.id)
      reloaded_step3 = Repo.get!(Userflow.StepModel, step3.id)

      assert reloaded_step3.order == step2.order
      assert reloaded_step2.order == step3.order
    end
  end
end
