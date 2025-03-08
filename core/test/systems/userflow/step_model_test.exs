defmodule Systems.Userflow.StepModelTest do
  use Core.DataCase, async: true
  alias Systems.Userflow.{StepModel, Factories}

  describe "changeset/2" do
    setup do
      userflow = Factories.create_userflow()
      {:ok, %{userflow: userflow}}
    end

    test "valid attributes", %{userflow: userflow} do
      changeset = Factories.build_step(userflow)
      assert changeset.valid?
    end

    test "invalid without identifier", %{userflow: userflow} do
      changeset = Factories.build_step(userflow, %{identifier: nil})
      assert "can't be blank" in errors_on(changeset).identifier
    end

    test "invalid without order", %{userflow: userflow} do
      changeset = Factories.build_step(userflow, %{order: nil})
      assert "can't be blank" in errors_on(changeset).order
    end

    test "invalid without group", %{userflow: userflow} do
      changeset = Factories.build_step(userflow, %{group: nil})
      assert "can't be blank" in errors_on(changeset).group
    end
  end

  describe "preload_graph/1" do
    test ":down includes progress" do
      assert [:progress] = StepModel.preload_graph(:down)
    end

    test ":up includes userflow" do
      assert [:userflow] = StepModel.preload_graph(:up)
    end
  end
end
