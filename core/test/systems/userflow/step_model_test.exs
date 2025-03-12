defmodule Systems.Userflow.StepModelTest do
  use Core.DataCase, async: true

  alias Systems.Userflow

  describe "schema" do
    test "has expected fields" do
      step = %Userflow.StepModel{}
      fields = step.__struct__.__schema__(:fields)

      assert :id in fields
      assert :order in fields
      assert :group in fields
      assert :userflow_id in fields
      assert :inserted_at in fields
      assert :updated_at in fields
    end

    test "has expected associations" do
      step = %Userflow.StepModel{}
      associations = step.__struct__.__schema__(:associations)

      assert :userflow in associations
      assert :progress in associations
    end
  end

  describe "validate/1" do
    setup do
      userflow = Userflow.Factory.insert(:userflow)
      {:ok, userflow: userflow}
    end

    test "valid attributes", %{userflow: userflow} do
      attrs = %{
        identifier: "step-1",
        order: 1,
        group: "group-1"
      }

      changeset =
        Userflow.StepModel.changeset(%Userflow.StepModel{}, attrs)
        |> Ecto.Changeset.put_assoc(:userflow, userflow)
        |> Userflow.StepModel.validate()

      assert changeset.valid?
    end

    test "invalid when missing required fields" do
      changeset =
        Userflow.StepModel.changeset(%Userflow.StepModel{}, %{})
        |> Userflow.StepModel.validate()

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).order
    end

    test "enforces unique order per userflow", %{userflow: userflow} do
      # Create first step
      attrs1 = %{
        identifier: "step-1",
        order: 1,
        group: "group-1"
      }

      %Userflow.StepModel{}
      |> Userflow.StepModel.changeset(attrs1)
      |> Ecto.Changeset.put_assoc(:userflow, userflow)
      |> Repo.insert!()

      assert_raise Ecto.ConstraintError, fn ->
        # Try to create second step with same order in same userflow
        attrs2 = %{
          identifier: "step-2",
          order: 1,
          group: "group-1"
        }

        %Userflow.StepModel{}
        |> Userflow.StepModel.changeset(attrs2)
        |> Ecto.Changeset.put_assoc(:userflow, userflow)
        |> Repo.insert!()
      end
    end
  end

  describe "preload_graph/1" do
    test ":down returns expected associations" do
      assert [:progress] == Userflow.StepModel.preload_graph(:down)
    end

    test ":up returns expected associations" do
      assert [:userflow] == Userflow.StepModel.preload_graph(:up)
    end
  end
end
