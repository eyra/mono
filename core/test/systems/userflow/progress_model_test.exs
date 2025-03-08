defmodule Systems.Userflow.ProgressModelTest do
  use Core.DataCase, async: true
  alias Systems.Userflow.{ProgressModel, Factories}

  setup do
    user = Core.Factories.insert!(%Systems.Account.User{email: "test@example.com"})
    userflow = Factories.create_userflow()
    step = Factories.create_step(userflow)
    {:ok, %{user: user, step: step}}
  end

  describe "changeset/2" do
    test "valid attributes", %{user: user, step: step} do
      changeset = Factories.build_progress(user, step)
      assert changeset.valid?
    end

    test "invalid without visited_at", %{user: user, step: step} do
      changeset = Factories.build_progress(user, step, %{visited_at: nil})
      assert "can't be blank" in errors_on(changeset).visited_at
    end
  end

  describe "mark_visited/1" do
    test "sets visited_at to current time", %{user: user, step: step} do
      changeset = Factories.build_progress(user, step, %{visited_at: nil})
      |> ProgressModel.mark_visited()

      assert %DateTime{} = get_change(changeset, :visited_at)
    end
  end

  describe "preload_graph/1" do
    test ":down returns empty list" do
      assert [] = ProgressModel.preload_graph(:down)
    end

    test ":up includes user and step" do
      assert [:user, :step] = ProgressModel.preload_graph(:up)
    end
  end
end
