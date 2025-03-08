defmodule Systems.Userflow.ModelTest do
  use Core.DataCase, async: true
  alias Systems.Userflow.{Model, Factories}

  describe "changeset/2" do
    test "valid attributes" do
      attrs = %{identifier: "test_flow", title: "Test Flow"}
      changeset = Model.changeset(%Model{}, attrs)
      assert changeset.valid?
    end

    test "invalid without identifier" do
      attrs = %{title: "Test Flow"}
      changeset = Model.changeset(%Model{}, attrs)
      assert "can't be blank" in errors_on(changeset).identifier
    end

    test "invalid without title" do
      attrs = %{identifier: "test_flow"}
      changeset = Model.changeset(%Model{}, attrs)
      assert "can't be blank" in errors_on(changeset).title
    end
  end

  describe "finished?/2" do
    setup do
      user = Core.Factories.insert!(%Systems.Account.User{email: "test@example.com"})

      userflow =
        Factories.create_complete_userflow(%{}, steps: 2, with_progress: user, visited_steps: 2)

      {:ok, %{userflow: userflow, user: user}}
    end

    test "returns true when all steps are visited", %{userflow: userflow, user: user} do
      assert Model.finished?(userflow, user.id)
    end

    test "returns false when not all steps are visited", %{userflow: userflow, user: user} do
      # Create a new userflow with only 1 of 2 steps visited
      userflow =
        Factories.create_complete_userflow(%{}, steps: 2, with_progress: user, visited_steps: 1)

      refute Model.finished?(userflow, user.id)
    end
  end

  describe "next_step/2" do
    setup do
      user = Core.Factories.insert!(%Systems.Account.User{email: "test@example.com"})

      userflow =
        Factories.create_complete_userflow(%{}, steps: 3, with_progress: user, visited_steps: 1)

      {:ok, %{userflow: userflow, user: user}}
    end

    test "returns first unvisited step", %{userflow: userflow, user: user} do
      next = Model.next_step(userflow, user.id)
      assert next.order == 2
    end

    test "returns nil when all steps visited", %{userflow: userflow, user: user} do
      # Create a new userflow with all steps visited
      userflow =
        Factories.create_complete_userflow(%{}, steps: 2, with_progress: user, visited_steps: 2)

      assert nil == Model.next_step(userflow, user.id)
    end
  end

  describe "steps_by_group/1" do
    setup do
      userflow =
        Factories.create_complete_userflow(%{},
          steps: 3,
          groups: ["intro", "intro", "main"]
        )

      {:ok, %{userflow: userflow}}
    end

    test "groups steps correctly", %{userflow: userflow} do
      result = Model.steps_by_group(userflow)

      assert map_size(result) == 2
      assert length(result["intro"]) == 2
      assert length(result["main"]) == 1
    end

    test "maintains order within groups", %{userflow: userflow} do
      result = Model.steps_by_group(userflow)

      [first, second] = result["intro"]
      assert first.order == 1
      assert second.order == 2
    end
  end
end
