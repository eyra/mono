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
end
