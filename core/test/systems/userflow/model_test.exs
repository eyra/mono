defmodule Systems.Userflow.ModelTest do
  use Core.DataCase, async: true

  alias Systems.Userflow

  describe "finished?/2" do
    setup do
      user = Core.Factories.insert!(:member)
      {:ok, user: user}
    end

    test "returns true when all steps have progress for the user" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.insert(:userflow)
      steps = Userflow.Factory.insert_list(3, :step, %{userflow: userflow})

      for step <- steps do
        Userflow.Factory.insert(:progress, %{user: user, step: step})
      end

      userflow =
        %{userflow | steps: steps}
        |> Repo.preload(steps: [:progress])

      assert Userflow.Model.finished?(userflow, user.id)
    end

    test "returns false when not all steps have progress" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow_started(user)
      userflow = Repo.preload(userflow, steps: [:progress])
      refute Userflow.Model.finished?(userflow, user.id)
    end

    test "returns false when some steps have progress" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow()
      userflow = Repo.preload(userflow, :steps)
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      # Add progress only to the first step
      Userflow.Factory.insert(:progress, %{
        step: first_step,
        user: user
      })

      userflow = Repo.preload(userflow, steps: [:progress])
      refute Userflow.Model.finished?(userflow, user.id)
    end
  end

  describe "next_step/2" do
    test "returns nil when all steps are completed" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow_finished(user)
      assert nil == Userflow.Model.next_step(userflow, user.id)
    end

    test "returns the first step when no progress exists" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow()
      userflow = Repo.preload(userflow, steps: [:progress])
      [first_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      assert first_step.id == Userflow.Model.next_step(userflow, user.id).id
    end

    test "returns the next incomplete step" do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factory.userflow()
      [first_step, second_step | _] = Enum.sort_by(userflow.steps, & &1.order)

      # Complete first step
      Userflow.Factory.insert(
        :progress,
        %{
          user: user,
          step: first_step
        }
      )

      userflow = Repo.preload(userflow, steps: [:progress])
      assert second_step.id == Userflow.Model.next_step(userflow, user.id).id
    end
  end

  describe "steps_by_group/1" do
    test "groups steps by their group attribute" do
      userflow = Userflow.Factory.userflow_finished()
      userflow = Repo.preload(userflow, steps: :userflow)
      groups = Userflow.Model.steps_by_group(userflow)

      assert Enum.all?(Map.keys(groups), &(&1 =~ ~r/group-\d+/))

      for {_group, steps} <- groups do
        assert is_list(steps)
        assert Enum.all?(steps, &(&1.userflow.id == userflow.id))
      end
    end

    test "returns empty map when userflow has no steps" do
      userflow = Userflow.Factory.insert(:userflow)
      userflow = %{userflow | steps: []}

      assert %{} == Userflow.Model.steps_by_group(userflow)
    end

    test "maintains step order within groups" do
      userflow = Userflow.Factory.userflow()
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
