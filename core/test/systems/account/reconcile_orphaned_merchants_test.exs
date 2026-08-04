defmodule Systems.Account.ReconcileOrphanedMerchantsTest do
  @moduledoc """
  Provider→local pass for merchants: flag provider accounts whose uid no user
  carries — the restore case that strands a participant, unable to be paid out
  and unable to re-register under the same email.
  """
  use Core.DataCase, async: true
  import Mox

  alias Core.Factories
  alias Systems.Account
  alias Systems.Payment
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp state, do: Payment.Public.new_reconciliation_state()

  defp merchant(uid, opts \\ []) do
    %{
      uid: uid,
      status: "live",
      kyc_level: 100,
      compliance_status: "verified",
      overview_url: nil,
      created: Keyword.get(opts, :created, hours_ago(24))
    }
  end

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours * 60 * 60, :second)

  defp run(merchants, opts \\ []) do
    expect(ProviderMock, :list_recent_merchants, fn _since -> {:ok, merchants} end)
    Account.Public.reconcile_orphaned_merchants(opts, state())
  end

  describe "orphan detection" do
    test "flags a merchant no user carries" do
      %{summary: summary, findings: findings} = run([merchant("mer_lost")])

      assert summary.missing_locally == 1
      assert summary.scanned == 1

      assert [
               %{
                 outcome: :missing_locally,
                 subject_type: :merchant,
                 subject_id: nil,
                 provider_uid: "mer_lost"
               }
             ] = findings
    end

    test "a merchant recorded on a user is verified, not flagged" do
      Factories.insert!(:member, %{creator: false, merchant_uid: "mer_known"})

      %{summary: summary, findings: findings} = run([merchant("mer_known")])

      assert summary.verified == 1
      assert summary.missing_locally == 0
      assert findings == []
    end

    test "separates known from unknown in one batch" do
      Factories.insert!(:member, %{creator: false, merchant_uid: "mer_known"})

      %{summary: summary} = run([merchant("mer_known"), merchant("mer_lost")])

      assert summary.scanned == 2
      assert summary.verified == 1
      assert summary.missing_locally == 1
    end
  end

  describe "the platform merchant" do
    setup do
      previous = Application.get_env(:core, Systems.Payment.Provider.OPP)

      Application.put_env(
        :core,
        Systems.Payment.Provider.OPP,
        Keyword.merge(previous || [], merchant_uid: "mer_platform")
      )

      on_exit(fn -> Application.put_env(:core, Systems.Payment.Provider.OPP, previous) end)
      :ok
    end

    test "is never flagged, having no user row by design" do
      # Without this it would be reported on every single run, training whoever
      # reads the findings to ignore them.
      %{summary: summary, findings: findings} = run([merchant("mer_platform")])

      assert summary.missing_locally == 0
      assert summary.scanned == 0
      assert findings == []
    end

    test "does not mask a real orphan alongside it" do
      %{summary: summary, findings: findings} =
        run([merchant("mer_platform"), merchant("mer_lost")])

      assert summary.missing_locally == 1
      assert [%{provider_uid: "mer_lost"}] = findings
    end
  end

  describe "windowing" do
    test "a merchant younger than min_age is left alone" do
      %{summary: summary} = run([merchant("mer_new", created: hours_ago(0))])

      assert summary.scanned == 0
      assert summary.missing_locally == 0
    end

    test "a merchant with no creation timestamp is still scanned" do
      %{summary: summary} = run([merchant("mer_undated", created: nil)])

      assert summary.missing_locally == 1
    end

    test "min_age_minutes is overridable" do
      %{summary: summary} = run([merchant("mer_new", created: hours_ago(1))], min_age_minutes: 0)

      assert summary.missing_locally == 1
    end
  end

  describe "provider failures" do
    test "a failed listing is tallied, not silently skipped" do
      expect(ProviderMock, :list_recent_merchants, fn _since ->
        {:error, %Payment.Error{code: :api_error, message: "boom"}}
      end)

      %{summary: summary, findings: findings} =
        Account.Public.reconcile_orphaned_merchants([], state())

      assert summary.errors == 1
      assert [%{outcome: :errors, subject_type: :merchant, subject_id: nil}] = findings
    end

    test "an open circuit skips the pass rather than reporting no orphans" do
      open_circuit =
        Enum.reduce(1..5, state(), fn _i, acc ->
          Payment.ReconciliationState.record_failure(acc)
        end)

      %{summary: summary} = Account.Public.reconcile_orphaned_merchants([], open_circuit)

      assert summary.skipped == 1
      assert summary.missing_locally == 0
    end
  end
end
