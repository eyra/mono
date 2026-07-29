defmodule Systems.Fund.RewardModelTest do
  use Core.DataCase

  alias Core.Factories
  alias Core.Repo
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

  describe "approved_requires_payment constraint" do
    test "the database rejects an :approved reward with no payment" do
      assert_raise Ecto.ConstraintError, ~r/approved_requires_payment/, fn ->
        Repo.insert!(reward(status: :approved, payment_id: nil))
      end
    end

    test "an :approved reward with a payment is allowed" do
      payment =
        Factories.insert!(:book_entry, %{
          idempotence_key: "pay-#{System.unique_integer([:positive])}",
          journal_message: "reward payment"
        })

      assert %Fund.RewardModel{status: :approved} =
               Repo.insert!(reward(status: :approved, payment_id: payment.id))
    end

    test "a non-approved reward with no payment is allowed" do
      assert %Fund.RewardModel{status: :reserved} = Repo.insert!(reward(status: :reserved))
    end
  end

  defp reward(attrs) do
    defaults = %{idempotence_key: "rwd-#{System.unique_integer([:positive])}", amount: 100}
    Factories.build(:reward, Map.merge(defaults, Map.new(attrs)))
  end
end
