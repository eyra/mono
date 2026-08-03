defmodule Systems.Fund.ReconcileOrphanedPayoutsTest do
  @moduledoc """
  Provider→local pass: given the withdrawals and transfers the provider holds,
  flag the ones whose payout has no local row — the restore-orphan case.
  """
  use Core.DataCase, async: true
  import Mox

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp state, do: Payment.Public.new_reconciliation_state()

  defp payout(attrs \\ %{}) do
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_orphan"})

    Repo.insert!(
      struct(
        %Fund.PayoutModel{
          user_id: user.id,
          amount_cents: 1000,
          currency: "eur",
          status: :pending
        },
        attrs
      )
    )
  end

  defp withdrawal(reference, opts \\ []) do
    %{
      uid: Keyword.get(opts, :uid, "wtd_#{System.unique_integer([:positive])}"),
      status: :completed,
      raw_status: "completed",
      reference: reference,
      amount: 1000,
      created: Keyword.get(opts, :created, hours_ago(24))
    }
  end

  defp transfer(reference, opts \\ []) do
    %{
      uid: Keyword.get(opts, :uid, "cha_#{System.unique_integer([:positive])}"),
      status: :completed,
      raw_status: "completed",
      reference: reference,
      amount: 1000,
      created: Keyword.get(opts, :created, hours_ago(24))
    }
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours * 60 * 60, :second)

  defp expect_listings(withdrawals, transfers) do
    expect(ProviderMock, :list_recent_withdrawals, fn _since -> {:ok, withdrawals} end)
    expect(ProviderMock, :list_recent_transfers, fn _since -> {:ok, transfers} end)
  end

  defp run(withdrawals, transfers \\ []) do
    expect_listings(withdrawals, transfers)
    Fund.Public.reconcile_orphaned_payouts([], state())
  end

  describe "orphan detection" do
    test "flags a withdrawal whose payout has no local row" do
      orphan_uid = Ecto.UUID.generate()

      %{summary: summary, findings: findings} =
        run([withdrawal("payout=#{orphan_uid},type=withdrawal,attempt=0", uid: "wtd_lost")])

      assert summary.missing_locally == 1
      assert summary.verified == 0
      assert summary.scanned == 1

      assert [
               %{
                 outcome: :missing_locally,
                 subject_type: :payout,
                 subject_id: nil,
                 provider_uid: "wtd_lost",
                 details: %{payout_uid: ^orphan_uid, leg: "withdrawal"}
               }
             ] = findings
    end

    test "flags a transfer whose payout has no local row" do
      orphan_uid = Ecto.UUID.generate()

      %{summary: summary, findings: findings} =
        run([], [transfer("payout=#{orphan_uid},type=transfer", uid: "cha_lost")])

      assert summary.missing_locally == 1
      assert [%{outcome: :missing_locally, details: %{leg: "transfer"}}] = findings
    end

    test "a payout that does exist locally is verified, not flagged" do
      %{uid: uid} = payout()

      %{summary: summary, findings: findings} =
        run(
          [withdrawal("payout=#{uid},type=withdrawal,attempt=0")],
          [transfer("payout=#{uid},type=transfer")]
        )

      assert summary.verified == 2
      assert summary.missing_locally == 0
      assert findings == []
    end

    test "scans both legs in one pass" do
      %{uid: known} = payout()
      orphan = Ecto.UUID.generate()

      %{summary: summary} =
        run(
          [withdrawal("payout=#{known},type=withdrawal,attempt=0")],
          [transfer("payout=#{orphan},type=transfer")]
        )

      assert summary.scanned == 2
      assert summary.verified == 1
      assert summary.missing_locally == 1
    end

    test "an orphan is found even when its payout uid repeats across both legs" do
      orphan = Ecto.UUID.generate()

      %{summary: summary} =
        run(
          [withdrawal("payout=#{orphan},type=withdrawal,attempt=0")],
          [transfer("payout=#{orphan},type=transfer")]
        )

      assert summary.missing_locally == 2
    end
  end

  describe "reference parsing" do
    test "a legacy serial-id reference is reported, never matched against a payout" do
      # Pre-UUID references carry fund_payouts.id, which a restore rewinds —
      # matching on one could pair a provider object with an unrelated payout.
      %{id: id} = payout()

      %{summary: summary, findings: findings} =
        run([withdrawal("payout=#{id},type=withdrawal")])

      assert summary.unresolvable == 1
      assert summary.verified == 0
      assert summary.missing_locally == 0
      assert [%{outcome: :unresolvable, details: %{reason: reason}}] = findings
      assert reason =~ "unrecognised withdrawal reference format"
    end

    test "an object with no reference at all is reported" do
      %{summary: summary, findings: findings} = run([withdrawal(nil)])

      assert summary.unresolvable == 1
      assert [%{outcome: :unresolvable, details: %{reason: "no reference"}}] = findings
    end

    test "an unrelated reference format is reported, not silently dropped" do
      %{summary: summary} = run([withdrawal("some-other-system=42")])

      assert summary.unresolvable == 1
      assert summary.scanned == 1
    end
  end

  describe "windowing" do
    test "an object younger than min_age is left alone" do
      orphan = Ecto.UUID.generate()
      recent = withdrawal("payout=#{orphan},type=withdrawal,attempt=0", created: hours_ago(0))

      expect_listings([recent], [])
      %{summary: summary} = Fund.Public.reconcile_orphaned_payouts([], state())

      assert summary.scanned == 0
      assert summary.missing_locally == 0
    end

    test "an object with no creation timestamp is still scanned" do
      orphan = Ecto.UUID.generate()

      %{summary: summary} =
        run([withdrawal("payout=#{orphan},type=withdrawal,attempt=0", created: nil)])

      assert summary.missing_locally == 1
    end

    test "min_age_minutes is overridable" do
      orphan = Ecto.UUID.generate()
      recent = withdrawal("payout=#{orphan},type=withdrawal,attempt=0", created: hours_ago(1))

      expect_listings([recent], [])
      %{summary: summary} = Fund.Public.reconcile_orphaned_payouts([min_age_minutes: 0], state())

      assert summary.missing_locally == 1
    end
  end

  describe "provider failures" do
    test "a failed listing is tallied once for the leg, not silently skipped" do
      expect(ProviderMock, :list_recent_withdrawals, fn _since ->
        {:error, %Payment.Error{code: :api_error, message: "boom"}}
      end)

      expect(ProviderMock, :list_recent_transfers, fn _since -> {:ok, []} end)

      %{summary: summary, findings: findings} =
        Fund.Public.reconcile_orphaned_payouts([], state())

      assert summary.errors == 1
      assert [%{outcome: :errors, subject_id: nil, details: %{leg: "withdrawal"}}] = findings
    end

    test "an open circuit skips the pass rather than reporting no orphans" do
      open_circuit =
        Enum.reduce(1..5, state(), fn _i, acc ->
          Payment.ReconciliationState.record_failure(acc)
        end)

      assert %{circuit_open: true} = open_circuit

      %{summary: summary} = Fund.Public.reconcile_orphaned_payouts([], open_circuit)

      assert summary.skipped == 2
      assert summary.missing_locally == 0
    end
  end
end
