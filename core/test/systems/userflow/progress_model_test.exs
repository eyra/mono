defmodule Systems.Userflow.ProgressModelTest do
  use Core.DataCase, async: true

  alias Systems.Userflow

  describe "schema" do
    test "has expected fields" do
      progress = %Userflow.ProgressModel{}
      fields = progress.__struct__.__schema__(:fields)

      assert :id in fields
      assert :visited_at in fields
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
      userflow = Userflow.Factories.insert!(:userflow)
      step = Userflow.Factories.insert!(:step, %{userflow_id: userflow.id})
      {:ok, user: user, step: step}
    end

    test "valid attributes", %{user: user, step: step} do
      attrs = %{
        visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset =
        %Userflow.ProgressModel{}
        |> Userflow.ProgressModel.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:step, step)

      assert changeset.valid?
    end

    test "invalid when missing required fields" do
      changeset = Userflow.ProgressModel.changeset(%Userflow.ProgressModel{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).visited_at
    end

    test "enforces unique user and step combination", %{user: user, step: step} do
      attrs = %{
        visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

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
      userflow = Userflow.Factories.insert!(:userflow)
      step = Userflow.Factories.insert!(:step, %{userflow_id: userflow.id})

      attrs = %{
        visited_at: DateTime.utc_now() |> DateTime.truncate(:second),
        user_id: user.id,
        step_id: step.id
      }

      progress = Userflow.Factories.insert!(:progress, attrs)
      {:ok, progress: progress}
    end

    test "updates visited_at timestamp", %{progress: progress} do
      old_visited_at = progress.visited_at
      # Ensure time difference
      :timer.sleep(1000)
      changeset = Userflow.ProgressModel.mark_visited(progress)

      assert changeset.valid?
      assert get_change(changeset, :visited_at) != old_visited_at
      assert DateTime.compare(get_change(changeset, :visited_at), old_visited_at) == :gt
    end
  end

  describe "preload_graph/1" do
    test ":down returns expected associations" do
      assert [] == Userflow.ProgressModel.preload_graph(:down)
    end

    test ":up returns expected associations" do
      assert [:user, :step] == Userflow.ProgressModel.preload_graph(:up)
    end
  end
end
