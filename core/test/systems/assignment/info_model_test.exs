defmodule Systems.Assignment.InfoModelTest do
  use Core.DataCase

  alias Systems.Assignment

  defp changeset(params, type \\ :auto_save),
    do: Assignment.InfoModel.changeset(%Assignment.InfoModel{}, type, params)

  describe "changeset/3 subject_reward" do
    test "defaults to 0 so an assignment without a reward is still valid" do
      assert %Assignment.InfoModel{}.subject_reward == 0

      assert changeset(%{}).valid?
    end

    test "casts an integer amount" do
      changeset = changeset(%{subject_reward: 250})

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :subject_reward) == 250
    end

    test "casts a numeric string, as submitted by the budget form" do
      changeset = changeset(%{"subject_reward" => "250"})

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :subject_reward) == 250
    end

    test "rejects a non-numeric amount instead of silently storing nil" do
      changeset = changeset(%{"subject_reward" => "abc"})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).subject_reward
    end

    test "is an operational field: it must be set before an assignment can go live" do
      assert :subject_reward in Assignment.InfoModel.operational_fields()
    end
  end

  describe "changeset/3 aim_of_study" do
    test "accepts a description within bounds" do
      changeset = changeset(%{aim_of_study: String.duplicate("a", 10)})

      assert changeset.valid?
    end

    test "rejects a description shorter than 10 characters" do
      changeset = changeset(%{aim_of_study: "too short"})

      refute changeset.valid?
      assert "should be at least 10 character(s)" in errors_on(changeset).aim_of_study
    end

    test "rejects a description longer than 250 characters" do
      changeset = changeset(%{aim_of_study: String.duplicate("a", 251)})

      refute changeset.valid?
      assert "should be at most 250 character(s)" in errors_on(changeset).aim_of_study
    end

    test "is optional: an empty draft still auto-saves" do
      assert changeset(%{}).valid?
    end

    test "length is validated on the non-auto_save clause too" do
      changeset = changeset(%{aim_of_study: "too short"}, :submit)

      refute changeset.valid?
      assert "should be at least 10 character(s)" in errors_on(changeset).aim_of_study
    end
  end

  describe "operational_validation/1" do
    test "fails while ethical approval is missing" do
      changeset =
        %{aim_of_study: String.duplicate("a", 10), subject_reward: 250}
        |> changeset()
        |> Assignment.InfoModel.operational_validation()

      refute changeset.valid?
      assert "is not true" in errors_on(changeset).ethical_approval
    end

    test "passes once ethical approval is given" do
      changeset =
        %{aim_of_study: String.duplicate("a", 10), subject_reward: 250, ethical_approval: true}
        |> changeset()
        |> Assignment.InfoModel.operational_validation()

      assert changeset.valid?
    end
  end
end
