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

  defp donation(attrs \\ %{}) do
    user = Factories.insert!(:member, %{creator: false})

    Repo.insert!(
      struct(
        %Fund.DonationModel{
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

  defp hours_ago(hours), do: DateTime.shift(DateTime.utc_now(), hour: -hours)

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
                 details: %{payout_uid: ^orphan_uid, source: "withdrawal"}
               }
             ] = findings
    end

    test "flags a transfer whose payout has no local row" do
      orphan_uid = Ecto.UUID.generate()

      %{summary: summary, findings: findings} =
        run([], [transfer("payout=#{orphan_uid},type=transfer", uid: "cha_lost")])

      assert summary.missing_locally == 1
      assert [%{outcome: :missing_locally, details: %{source: "transfer"}}] = findings
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

  # Donation charges share the provider's transfer listing with payout transfers,
  # so a scan that only knew `payout=` would report every donation as
  # unresolvable and bury the findings that mean something.
  describe "donation charges" do
    test "a donation that exists locally is verified, not flagged" do
      %{uid: uid} = donation()

      %{summary: summary, findings: findings} =
        run([], [transfer("donation=#{uid},type=charge")])

      assert summary.verified == 1
      assert summary.unresolvable == 0
      assert findings == []
    end

    test "flags a donation charge whose donation has no local row" do
      orphan_uid = Ecto.UUID.generate()

      %{summary: summary, findings: findings} =
        run([], [transfer("donation=#{orphan_uid},type=charge", uid: "cha_donation")])

      assert summary.missing_locally == 1

      assert [
               %{
                 outcome: :missing_locally,
                 subject_type: :donation,
                 provider_uid: "cha_donation",
                 details: %{donation_uid: ^orphan_uid}
               }
             ] = findings
    end

    # A donation uid and a payout uid must never satisfy each other's lookup.
    test "a donation uid is not matched against a payout row" do
      %{uid: uid} = payout()

      %{summary: summary} = run([], [transfer("donation=#{uid},type=charge")])

      assert summary.missing_locally == 1
      assert summary.verified == 0
    end

    test "both kinds are resolved in one listing" do
      %{uid: payout_uid} = payout()
      %{uid: donation_uid} = donation()

      %{summary: summary} =
        run([], [
          transfer("payout=#{payout_uid},type=transfer"),
          transfer("donation=#{donation_uid},type=charge")
        ])

      assert summary.verified == 2
      assert summary.missing_locally == 0
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
      assert [%{outcome: :errors, subject_id: nil, details: %{source: "withdrawal"}}] = findings
    end

    test "a truncated listing is recorded, so a partial sweep cannot read as a clean one" do
      orphan = Ecto.UUID.generate()

      expect(ProviderMock, :list_recent_withdrawals, fn _since ->
        {:truncated, [withdrawal("payout=#{orphan},type=withdrawal,attempt=0")]}
      end)

      expect(ProviderMock, :list_recent_transfers, fn _since -> {:ok, []} end)

      %{summary: summary, findings: findings} =
        Fund.Public.reconcile_orphaned_payouts([], state())

      assert summary.errors == 1

      assert Enum.any?(
               findings,
               &(&1.outcome == :errors and &1.details.error =~ "truncated")
             )
    end

    test "objects returned alongside a truncation are still scanned" do
      orphan = Ecto.UUID.generate()

      expect(ProviderMock, :list_recent_withdrawals, fn _since ->
        {:truncated, [withdrawal("payout=#{orphan},type=withdrawal,attempt=0", uid: "wtd_lost")]}
      end)

      expect(ProviderMock, :list_recent_transfers, fn _since -> {:ok, []} end)

      %{summary: summary, findings: findings} =
        Fund.Public.reconcile_orphaned_payouts([], state())

      assert summary.missing_locally == 1
      assert Enum.any?(findings, &(&1.provider_uid == "wtd_lost"))
    end

    test "a truncated listing does not push the circuit breaker toward open" do
      # It is a call that succeeded and returned partial data, not a fault.
      expect(ProviderMock, :list_recent_withdrawals, fn _since -> {:truncated, []} end)
      expect(ProviderMock, :list_recent_transfers, fn _since -> {:ok, []} end)

      assert %{consecutive_failures: 0, circuit_open: false} =
               Fund.Public.reconcile_orphaned_payouts([], state())
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
