defmodule Systems.Payment.ReconciliationFindingModelTest do
  @moduledoc """
  One row per non-trivial reconciliation outcome. Findings are what a human
  reviews after a sweep, so a finding that fails to identify its subject is
  worse than no finding at all — hence the required set.
  """
  use Core.DataCase, async: true

  alias Systems.Payment.ReconciliationFindingModel, as: Finding
  alias Systems.Payment.ReconciliationSummary, as: Summary

  @valid %{
    reconciliation_run_id: 1,
    subject_type: :payout,
    subject_id: 42,
    outcome: :missing_at_provider
  }

  defp changeset(attrs \\ %{}), do: Finding.changeset(%Finding{}, Map.merge(@valid, attrs))

  describe "outcomes/0" do
    test "lists the outcomes worth persisting" do
      assert Finding.outcomes() == [
               :resolved_completed,
               :resolved_failed,
               :missing_at_provider,
               :unresolvable,
               :errors,
               :skipped
             ]
    end

    test "is a subset of the summary outcomes: trivial ones are counted, not stored" do
      assert Finding.outcomes() -- Summary.outcomes() == []
      assert Summary.outcomes() -- Finding.outcomes() == [:still_pending, :verified]
    end
  end

  describe "changeset/2 required fields" do
    test "accepts a minimal finding" do
      assert changeset().valid?
    end

    test "rejects a finding with no run to hang off" do
      changeset = Finding.changeset(%Finding{}, Map.delete(@valid, :reconciliation_run_id))

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).reconciliation_run_id
    end

    test "rejects a finding without a subject_type" do
      changeset = Finding.changeset(%Finding{}, Map.delete(@valid, :subject_type))

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).subject_type
    end

    test "rejects a finding without a subject_id" do
      changeset = Finding.changeset(%Finding{}, Map.delete(@valid, :subject_id))

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).subject_id
    end

    test "rejects a finding without an outcome" do
      changeset = Finding.changeset(%Finding{}, Map.delete(@valid, :outcome))

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).outcome
    end
  end

  describe "changeset/2 enums" do
    test "accepts a transaction subject" do
      assert changeset(%{subject_type: :transaction}).valid?
    end

    test "rejects a subject_type outside the enum" do
      changeset = changeset(%{subject_type: :merchant})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).subject_type
    end

    test "rejects :still_pending, which is counted on the run and never stored" do
      changeset = changeset(%{outcome: :still_pending})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).outcome
    end

    test "rejects :verified, which is counted on the run and never stored" do
      changeset = changeset(%{outcome: :verified})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).outcome
    end
  end

  describe "changeset/2 optional fields" do
    test "is valid without the provider context: an unresolvable row has none" do
      changeset = changeset(%{outcome: :unresolvable})

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :provider_uid)
      refute Map.has_key?(changeset.changes, :provider_status)
    end

    test "casts the provider context when the row could be looked up" do
      changeset =
        changeset(%{
          provider_uid: "w_payout",
          local_status_before: "pending",
          provider_status: "completed",
          outcome: :resolved_completed
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :provider_uid) == "w_payout"
      assert Ecto.Changeset.get_change(changeset, :local_status_before) == "pending"
      assert Ecto.Changeset.get_change(changeset, :provider_status) == "completed"
    end

    test "casts free-form details for manual review" do
      changeset = changeset(%{details: %{"reason" => "no provider uid recorded"}})

      assert changeset.valid?

      assert Ecto.Changeset.get_change(changeset, :details) == %{
               "reason" => "no provider uid recorded"
             }
    end
  end
end
