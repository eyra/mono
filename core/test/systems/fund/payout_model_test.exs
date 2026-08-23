defmodule Systems.Fund.PayoutModelTest do
  use ExUnit.Case, async: true

  alias Systems.Fund.PayoutModel

  defp payout(attrs \\ %{}) do
    struct!(
      %PayoutModel{uid: "3f1c0b6e-1f5a-4a2e-9d0e-2b6c9a1d7e42", withdrawal_attempt: 0},
      attrs
    )
  end

  describe "phase/1" do
    test "a payout the provider completed is :completed" do
      assert :completed = PayoutModel.phase(payout(%{status: :completed}))
    end

    # The transfer never landed, so the lock was released and nothing moved. This
    # is the only :failed that is safe to leave alone.
    test "a payout that failed before the funds moved is :failed" do
      assert :failed = PayoutModel.phase(payout(%{status: :failed, funds_committed_at: nil}))
    end

    # The money is on the participant's merchant and the rewards are still locked.
    # Releasing them would let a later payout charge the platform a second time,
    # so this must be recovered by issuing a fresh withdrawal.
    test "a payout that failed after the funds moved is :withdrawal_retryable" do
      assert :withdrawal_retryable =
               PayoutModel.phase(
                 payout(%{
                   status: :failed,
                   funds_committed_at: ~N[2026-07-14 09:00:00],
                   provider_uid: "w_1"
                 })
               )
    end

    test "a pending payout whose transfer is unconfirmed is :awaiting_transfer" do
      assert :awaiting_transfer =
               PayoutModel.phase(payout(%{status: :pending, funds_committed_at: nil}))
    end

    # The stranded state: funds moved, but no withdrawal uid was recorded.
    test "a pending payout with committed funds and no withdrawal is :awaiting_withdrawal" do
      assert :awaiting_withdrawal =
               PayoutModel.phase(
                 payout(%{
                   status: :pending,
                   funds_committed_at: ~N[2026-07-14 09:00:00],
                   provider_uid: nil
                 })
               )
    end

    test "a pending payout with an issued withdrawal is :awaiting_provider" do
      assert :awaiting_provider =
               PayoutModel.phase(
                 payout(%{
                   status: :pending,
                   funds_committed_at: ~N[2026-07-14 09:00:00],
                   provider_uid: "w_1"
                 })
               )
    end
  end

  describe "idempotency keys" do
    test "the transfer key carries no attempt counter" do
      # A transfer is never re-issued under a fresh key: replaying the same key is
      # de-duplicated by the provider, but minting a new one moves the money twice.
      key = PayoutModel.transfer_key(payout(%{withdrawal_attempt: 3}))

      assert key == "payout=3f1c0b6e-1f5a-4a2e-9d0e-2b6c9a1d7e42,type=transfer"
      refute key =~ "attempt"
    end

    test "the withdrawal key carries the attempt counter" do
      # A withdrawal the provider created and then rejected keeps its key, so a
      # retry has to present a fresh one.
      assert PayoutModel.withdrawal_key(payout(%{withdrawal_attempt: 0})) !=
               PayoutModel.withdrawal_key(payout(%{withdrawal_attempt: 1}))
    end

    test "every withdrawal attempt shares the prefix a stranded withdrawal is found by" do
      prefix = PayoutModel.withdrawal_key_prefix(payout())

      for attempt <- 0..2 do
        assert PayoutModel.withdrawal_key(payout(%{withdrawal_attempt: attempt})) =~ prefix
      end
    end

    # The restore-stability property (money-flow audit #9): keys derive from the
    # uid, not the serial id, so a restore that rewinds the id sequence cannot
    # make a later payout reuse a key the provider has already processed — nor
    # make two payouts share a `reference` at the provider.
    test "two payouts never share a key, even on the same id" do
      a = %PayoutModel{id: 1, uid: Ecto.UUID.generate(), withdrawal_attempt: 0}
      b = %PayoutModel{id: 1, uid: Ecto.UUID.generate(), withdrawal_attempt: 0}

      refute PayoutModel.transfer_key(a) == PayoutModel.transfer_key(b)
      refute PayoutModel.withdrawal_key(a) == PayoutModel.withdrawal_key(b)
    end
  end
end
