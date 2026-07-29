defmodule Systems.Fund.RewardModelTest do
  use Core.DataCase

  alias Systems.Fund

  describe "status field" do
    test "defaults to :reserved on a fresh struct" do
      assert %Fund.RewardModel{}.status == :reserved
    end

    test "statuses/0 lists every state in the reward lifecycle" do
      assert Fund.RewardModel.statuses() == [
               :reserved,
               :pending_approval,
               :approved,
               :pending_payout,
               :rejected,
               :paid
             ]
    end

    test "changeset accepts a valid status" do
      changeset =
        Fund.RewardModel.changeset(%Fund.RewardModel{}, %{
          idempotence_key: "key",
          amount: 100,
          status: :approved
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :status) == :approved
    end

    test "changeset rejects an unknown status" do
      changeset =
        Fund.RewardModel.changeset(%Fund.RewardModel{}, %{
          idempotence_key: "key",
          amount: 100,
          status: :bogus
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "rejection fields" do
    test "are nil on a fresh struct" do
      assert %Fund.RewardModel{}.rejection_reason == nil
      assert %Fund.RewardModel{}.rejected_at == nil
    end

    test "changeset is valid without them: a reward only carries them once rejected" do
      changeset =
        Fund.RewardModel.changeset(%Fund.RewardModel{}, %{
          idempotence_key: "key",
          amount: 100,
          status: :pending_approval
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :rejection_reason)
      refute Map.has_key?(changeset.changes, :rejected_at)
    end

    test "changeset casts both when a reward is rejected" do
      rejected_at = ~N[2026-07-29 10:00:00]

      changeset =
        Fund.RewardModel.changeset(%Fund.RewardModel{}, %{
          idempotence_key: "key",
          amount: 100,
          status: :rejected,
          rejection_reason: "Task not completed",
          rejected_at: rejected_at
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :rejection_reason) == "Task not completed"
      assert Ecto.Changeset.get_change(changeset, :rejected_at) == rejected_at
    end

    test "changeset clears both when a rejection is overridden" do
      rejected =
        %Fund.RewardModel{
          status: :rejected,
          rejection_reason: "Task not completed",
          rejected_at: ~N[2026-07-29 10:00:00]
        }

      changeset =
        Fund.RewardModel.changeset(rejected, %{
          idempotence_key: "key",
          amount: 100,
          status: :approved,
          rejection_reason: nil,
          rejected_at: nil
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rejection_reason) == nil
      assert Ecto.Changeset.get_field(changeset, :rejected_at) == nil
    end
  end
end
