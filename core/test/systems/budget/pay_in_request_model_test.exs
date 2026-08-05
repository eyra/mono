defmodule Systems.Budget.PayInRequestModelTest do
  @moduledoc """
  Validation coverage for the pay-in request form-object.

  Reward is deliberately *not* validated here — reward = 0 is a
  legitimate domain state (free pay-in in a paid environment).
  """

  use ExUnit.Case, async: true

  alias Systems.Budget.PayInRequestModel

  defp validate(attrs) do
    %PayInRequestModel{}
    |> PayInRequestModel.changeset(attrs)
    |> PayInRequestModel.validate()
  end

  describe "validate/1 — subject_count" do
    test "flags a zero count on empty submit" do
      changeset = validate(%{})
      refute changeset.valid?
      assert changeset.errors[:subject_count]
    end

    test "flags an explicit zero count" do
      changeset =
        validate(%{"subject_count" => 0, "subject_reward" => "0", "aim_of_study" => valid_aim()})

      refute changeset.valid?
      assert changeset.errors[:subject_count]
    end

    test "passes with a positive count" do
      changeset =
        validate(%{"subject_count" => 5, "subject_reward" => "0", "aim_of_study" => valid_aim()})

      assert changeset.valid?
    end
  end

  describe "validate/1 — subject_reward" do
    test "flags a missing reward" do
      changeset = validate(%{"subject_count" => 5, "aim_of_study" => valid_aim()})
      refute changeset.valid?
      assert changeset.errors[:subject_reward]
    end

    test "flags a blank reward" do
      changeset =
        validate(%{"subject_count" => 5, "subject_reward" => "", "aim_of_study" => valid_aim()})

      refute changeset.valid?
      assert changeset.errors[:subject_reward]
    end

    test "accepts an explicit zero reward (unpaid study)" do
      changeset =
        validate(%{"subject_count" => 5, "subject_reward" => "0", "aim_of_study" => valid_aim()})

      assert changeset.valid?
    end

    test "accepts a decimal reward string with dot separator" do
      changeset =
        validate(%{
          "subject_count" => 5,
          "subject_reward" => "5.00",
          "aim_of_study" => valid_aim()
        })

      assert changeset.valid?
    end

    test "accepts a decimal reward string with comma separator" do
      changeset =
        validate(%{
          "subject_count" => 5,
          "subject_reward" => "5,00",
          "aim_of_study" => valid_aim()
        })

      assert changeset.valid?
    end
  end

  describe "validate/1 — aim_of_study" do
    test "flags a missing aim" do
      changeset = validate(%{"subject_count" => 5})
      refute changeset.valid?
      assert changeset.errors[:aim_of_study]
    end

    test "flags an empty aim" do
      changeset = validate(%{"subject_count" => 5, "aim_of_study" => ""})
      refute changeset.valid?
      assert changeset.errors[:aim_of_study]
    end

    test "accepts a short but non-empty aim" do
      changeset =
        validate(%{"subject_count" => 5, "subject_reward" => "0", "aim_of_study" => "hi"})

      assert changeset.valid?
    end

    test "flags an aim longer than 250 characters" do
      long_aim = String.duplicate("a", 251)

      changeset =
        validate(%{"subject_count" => 5, "subject_reward" => "0", "aim_of_study" => long_aim})

      refute changeset.valid?
      assert changeset.errors[:aim_of_study]
    end
  end

  defp valid_aim, do: "A study aim."
end
