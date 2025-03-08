defmodule Systems.Userflow.PublicTest do
  use Core.DataCase, async: true
  alias Systems.Userflow.{Public, Factories}

  setup do
    user = Core.Factories.insert!(%Systems.Account.User{email: "test@example.com"})
    {:ok, %{user: user}}
  end

  describe "create/2" do
    test "creates a userflow with valid attributes" do
      assert {:ok, userflow} = Public.create("test_flow", "Test Flow")
      assert userflow.identifier == "test_flow"
      assert userflow.title == "Test Flow"
    end

    test "fails with invalid attributes" do
      assert {:error, _changeset} = Public.create("", "")
    end
  end

  describe "add_step/4" do
    setup %{user: _user} do
      userflow = Factories.create_userflow()
      {:ok, %{userflow: userflow}}
    end

    test "adds a step to userflow", %{userflow: userflow} do
      assert {:ok, step} = Public.add_step(userflow, "welcome", 1, "intro")
      assert step.identifier == "welcome"
      assert step.order == 1
      assert step.group == "intro"
      assert step.userflow_id == userflow.id
    end

    test "fails with invalid attributes", %{userflow: userflow} do
      assert {:error, _changeset} = Public.add_step(userflow, "", nil, "")
    end

    test "maintains unique order within userflow", %{userflow: userflow} do
      Factories.create_step(userflow, %{order: 1})
      assert {:error, changeset} = Public.add_step(userflow, "step2", 1, "intro")
      assert {"has already been taken"} in errors_on(changeset).order
    end
  end

  describe "mark_visited/2" do
    setup %{user: user} do
      userflow = Factories.create_userflow()
      step = Factories.create_step(userflow)
      {:ok, %{step: step, user: user}}
    end

    test "marks a step as visited", %{step: step, user: user} do
      assert {:ok, progress} = Public.mark_visited(user.id, step.id)
      assert progress.user_id == user.id
      assert progress.step_id == step.id
      assert %DateTime{} = progress.visited_at
    end

    test "updates existing progress", %{step: step, user: user} do
      {:ok, progress1} = Public.mark_visited(user.id, step.id)
      {:ok, progress2} = Public.mark_visited(user.id, step.id)
      assert progress1.id == progress2.id
      assert progress1.visited_at != progress2.visited_at
    end
  end

  describe "next_step/2" do
    setup %{user: user} do
      userflow = Factories.create_complete_userflow(%{},
        steps: 2,
        with_progress: user,
        visited_steps: 1
      )
      {:ok, %{userflow: userflow, user: user}}
    end

    test "returns first unvisited step", %{userflow: userflow, user: user} do
      next_step = Public.next_step(userflow.identifier, user.id)
      assert next_step.order == 2
    end
  end

  describe "finished?/2" do
    setup %{user: user} do
      userflow = Factories.create_complete_userflow(%{},
        steps: 2,
        with_progress: user,
        visited_steps: 2
      )
      {:ok, %{userflow: userflow, user: user}}
    end

    test "returns true when all steps visited", %{userflow: userflow, user: user} do
      assert Public.finished?(userflow.identifier, user.id)
    end

    test "returns false when not all steps visited", %{userflow: userflow, user: user} do
      # Create a new userflow with only 1 of 2 steps visited
      userflow = Factories.create_complete_userflow(%{},
        steps: 2,
        with_progress: user,
        visited_steps: 1
      )
      refute Public.finished?(userflow.identifier, user.id)
    end
  end

  describe "steps_by_group/1" do
    setup do
      userflow = Factories.create_complete_userflow(%{},
        steps: 3,
        groups: ["intro", "intro", "main"]
      )
      {:ok, %{userflow: userflow}}
    end

    test "returns steps grouped by group", %{userflow: userflow} do
      groups = Public.steps_by_group(userflow.identifier)
      assert map_size(groups) == 2
      assert length(groups["intro"]) == 2
      assert length(groups["main"]) == 1
    end
  end
end
