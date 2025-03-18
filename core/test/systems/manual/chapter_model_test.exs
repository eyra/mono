defmodule Systems.Manual.ChapterModelTest do
  use Core.DataCase

  alias Systems.Manual.ChapterModel

  describe "changeset/2" do
    test "with valid attributes" do
      valid_attrs = %{title: "Test Chapter"}

      changeset = ChapterModel.changeset(%ChapterModel{}, valid_attrs)
      assert changeset.valid?
      assert get_change(changeset, :title) == "Test Chapter"
    end

    test "with invalid attributes" do
      invalid_attrs = %{}
      changeset = ChapterModel.changeset(%ChapterModel{}, invalid_attrs)
      # Should be valid as validation is separate
      assert changeset.valid?
    end
  end

  describe "validate/1" do
    test "with valid attributes" do
      valid_attrs = %{
        title: "Test Chapter",
        description: "Test Description"
      }

      changeset =
        %ChapterModel{}
        |> ChapterModel.changeset(valid_attrs)
        |> ChapterModel.validate()

      assert changeset.valid?
    end
  end

  describe "preload_graph/1" do
    test "down includes userflow_step and userflow" do
      assert ChapterModel.preload_graph(:down) ==
               [
                 {:pages, [:userflow_step]},
                 {:userflow, [steps: [progress: [user: []]]]},
                 {:userflow_step, [progress: [user: []]]}
               ]
    end

    test "up includes manual" do
      assert ChapterModel.preload_graph(:up) == [{:manual, []}]
    end
  end
end
