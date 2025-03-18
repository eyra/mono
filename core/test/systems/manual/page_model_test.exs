defmodule Systems.Manual.PageModelTest do
  use Core.DataCase, async: true

  alias Systems.Manual
  alias Systems.Userflow

  describe "validate/2" do
    test "with valid attributes" do
      userflow = Userflow.Factory.insert(:userflow)
      userflow_step = Userflow.Factory.insert(:step, %{userflow: userflow})

      attrs = %{
        title: "Test Page",
        text: "Test Text",
        image: "test.jpg"
      }

      changeset =
        Manual.PageModel.changeset(%Manual.PageModel{}, attrs)
        |> put_assoc(:userflow_step, userflow_step)
        |> Manual.PageModel.validate()

      assert changeset.valid?

      assert get_field(changeset, :title) == "Test Page"
      assert get_field(changeset, :text) == "Test Text"
      assert get_field(changeset, :image) == "test.jpg"
      assert get_field(changeset, :userflow_step).id == userflow_step.id
    end
  end

  describe "preload_graph/1" do
    test "returns correct preload paths" do
      assert Manual.PageModel.preload_graph(:down) == [:userflow_step]
      assert Manual.PageModel.preload_graph(:up) == []
    end
  end
end
