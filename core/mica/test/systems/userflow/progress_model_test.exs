defmodule Systems.Userflow.ProgressModelTest do
  use Core.DataCase, async: true

  alias Systems.Userflow

  describe "schema" do
    test "has expected fields" do
      progress = %Userflow.ProgressModel{}
      fields = progress.__struct__.__schema__(:fields)

      assert :id in fields
      assert :user_id in fields
      assert :step_id in fields
      assert :inserted_at in fields
      assert :updated_at in fields
    end

    test "has expected associations" do
      progress = %Userflow.ProgressModel{}
      associations = progress.__struct__.__schema__(:associations)

      assert :user in associations
      assert :step in associations
    end
  end

  describe "changeset/2" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factories.insert(:userflow)
      step = Userflow.Factories.insert(:step, %{userflow: userflow})
      {:ok, user: user, step: step}
    end

    test "valid attributes", %{user: user, step: step} do
      attrs = %{}

      changeset =
        %Userflow.ProgressModel{}
        |> Userflow.ProgressModel.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:step, step)

      assert changeset.valid?
    end

    test "enforces unique user and step combination", %{user: user, step: step} do
      attrs = %{}

      # Create first progress
      %Userflow.ProgressModel{}
      |> Userflow.ProgressModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Ecto.Changeset.put_assoc(:step, step)
      |> Repo.insert!()

      assert_raise Ecto.ConstraintError, fn ->
        # Try to create second progress with same user and step
        %Userflow.ProgressModel{}
        |> Userflow.ProgressModel.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:step, step)
        |> Repo.insert!()
      end
    end
  end

  describe "mark_visited/1" do
    setup do
      user = Core.Factories.insert!(:member)
      userflow = Userflow.Factories.insert(:userflow)
      step = Userflow.Factories.insert(:step, %{userflow: userflow})

      attrs = %{
        user: user,
        step: step
      }

      progress = Userflow.Factories.insert(:progress, attrs)
      {:ok, progress: progress}
    end
  end

  describe "preload_graph/1" do
    test ":down returns expected associations" do
      assert [{:user, []}] == Userflow.ProgressModel.preload_graph(:down)
    end

    test ":up returns expected associations" do
      assert [step: [{:userflow, []}]] == Userflow.ProgressModel.preload_graph(:up)
    end
  end
end
