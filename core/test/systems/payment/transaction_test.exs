defmodule Systems.Payment.TransactionTest do
  use ExUnit.Case, async: true

  alias Systems.Payment.Transaction

  describe "Description.format/2" do
    test "formats description with all fields" do
      description = %Transaction.Description{
        platform: "Eyra Next",
        assignment: "Data Donation TikTok",
        participant_count: 100,
        amount_per_participant: 250
      }

      assert Transaction.Description.format(description, "NEXT-NL-0128") ==
               "Eyra Next, Data Donation TikTok, Invoice NEXT-NL-0128, 100 participants x €2.50"
    end

    test "formats whole euro amounts" do
      description = %Transaction.Description{
        platform: "Eyra Next",
        assignment: "Survey",
        participant_count: 50,
        amount_per_participant: 500
      }

      assert Transaction.Description.format(description, "NEXT-NL-0129") ==
               "Eyra Next, Survey, Invoice NEXT-NL-0129, 50 participants x €5.00"
    end

    test "formats sub-euro amounts" do
      description = %Transaction.Description{
        platform: "Eyra Next",
        assignment: "Survey",
        participant_count: 1,
        amount_per_participant: 5
      }

      assert Transaction.Description.format(description, "NEXT-NL-0130") ==
               "Eyra Next, Survey, Invoice NEXT-NL-0130, 1 participants x €0.05"
    end

    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(Transaction.Description, %{platform: "Eyra Next"})
      end
    end
  end

  describe "Metadata.to_map/2" do
    test "converts struct to map with invoice_id" do
      metadata = %Transaction.Metadata{
        contact_person: "Dr. Jane Smith",
        study_title: "TikTok Data Donation Study",
        study_goal: "Analyze social media usage patterns",
        participant_count: 100,
        amount_per_participant: 250
      }

      result = Transaction.Metadata.to_map(metadata, "NEXT-NL-0128")

      assert result == %{
               contact_person: "Dr. Jane Smith",
               study_title: "TikTok Data Donation Study",
               study_goal: "Analyze social media usage patterns",
               participant_count: 100,
               amount_per_participant: 250,
               invoice_id: "NEXT-NL-0128"
             }
    end

    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(Transaction.Metadata, %{contact_person: "Jane"})
      end
    end
  end
end
