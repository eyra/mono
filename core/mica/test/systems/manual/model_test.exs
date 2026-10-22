defmodule Systems.Manual.ModelTest do
  use Core.DataCase

  alias Systems.Manual.Model
  alias Systems.Userflow

  describe "changeset/2" do
    test "with valid attributes" do
      valid_attrs = %{
        title: "Test Manual",
        description: "Test Description"
      }

      changeset = Model.changeset(%Model{}, valid_attrs)
      assert changeset.valid?
      assert get_change(changeset, :title) == "Test Manual"
      assert get_change(changeset, :description) == "Test Description"
    end

    test "with empty attributes" do
      changeset = Model.changeset(%Model{}, %{})
      # Should be valid as validation is separate
      assert changeset.valid?
    end

    test "with nil attributes" do
      changeset = Model.changeset(%Model{}, %{title: nil, description: nil})
      # Should be valid as no fields are required
      assert changeset.valid?
    end
  end

  describe "validate/1" do
    test "with valid attributes" do
      valid_attrs = %{
        title: "Test Manual",
        description: "Test Description"
      }

      changeset =
        %Model{}
        |> Model.changeset(valid_attrs)
        |> Model.validate()

      assert changeset.valid?
    end

    test "with empty attributes" do
      changeset =
        %Model{}
        |> Model.changeset(%{})
        |> Model.validate()

      # No required fields
      assert changeset.valid?
    end
  end

  describe "associations" do
    test "belongs to userflow" do
      userflow = Userflow.Factories.insert(:userflow)
      manual = Systems.Manual.Factories.insert(:manual, %{userflow: userflow})

      manual = Repo.preload(manual, :userflow)
      assert manual.userflow.id == userflow.id
    end
  end

  describe "preload_graph/1" do
    test "down includes userflow" do
      assert Model.preload_graph(:down) == [
               {:chapters,
                [
                  pages: [:userflow_step],
                  userflow: [steps: [progress: [user: []]]],
                  userflow_step: [progress: [user: []]]
                ]},
               {:userflow, [steps: [progress: [user: []]]]}
             ]
    end

    test "up is empty" do
      assert Model.preload_graph(:up) == []
    end
  end
end
